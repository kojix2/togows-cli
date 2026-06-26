# frozen_string_literal: true

require "json"
require "optparse"
require "shellwords"
require "timeout"

module TogoWS
  class CLI
    DEFAULT_BASE_URL = "https://togows.org"
    DEFAULT_TIMEOUT = 30

    def initialize(argv, stdin, stdout, stderr)
      @argv = argv.dup
      @stdin = stdin
      @stdout = stdout
      @stderr = stderr
      @out_color = Color.new(Color.enabled_for?(stdout))
      @err_color = Color.new(Color.enabled_for?(stderr))
    end

    def run
      command = @argv.shift
      return help_for(@argv.shift, 0) if ["help", "-h", "--help"].include?(command)
      return help(nil, 0) if command.nil?
      return version if ["version", "--version", "-v"].include?(command)

      case command
      when "entry" then run_entry
      when "search" then run_search
      when "convert" then run_convert
      when "databases", "dbs" then run_databases
      when "ucsc" then run_ucsc
      else
        error("unknown command: #{command}")
        help(nil, 2)
      end
    rescue HTTPError => e
      error("#{e.code} #{e.message_text}")
      @stderr.puts e.body unless e.body.empty?
      e.code >= 500 ? 5 : 4
    rescue OptionParser::ParseError, Error => e
      error(e.message)
      2
    rescue SystemCallError, SocketError, Timeout::Error => e
      error("#{e.class}: #{e.message}")
      6
    end

    private

    def common_options
      {
        base_url: DEFAULT_BASE_URL,
        timeout: DEFAULT_TIMEOUT,
        format: nil,
        raw_url: false,
        pager: false,
        pretty: false
      }
    end

    def parser(options, banner)
      OptionParser.new do |opts|
        opts.banner = banner
        opts.on("-f", "--format FORMAT", "Output format") { |v| options[:format] = v }
        opts.on("--base-url URL", "Base URL") { |v| options[:base_url] = v }
        opts.on("--timeout SEC", Integer, "Timeout seconds") { |v| options[:timeout] = v }
        opts.on("--raw-url", "Print URL and exit") { options[:raw_url] = true }
        opts.on("--pager", "Page output with PAGER when stdout is a terminal") { options[:pager] = true }
        opts.on("--pretty", "Pretty-print JSON output") { options[:pretty] = true }
        opts.on("-h", "--help", "Show help") do
          @stdout.puts opts
          throw :help
        end
      end
    end

    def run_entry
      options = common_options
      catch(:help) do
        parser(options, "Usage: togows entry DATABASE ID[,ID...] [FIELD] [options]").parse!(@argv)
        database, *rest = @argv
        return command_help(:entry, "entry requires DATABASE and ID", 2) if database.nil? || rest.empty?

        ids, field = parse_entry_arguments(rest)
        path = URLBuilder.entry(database, ids, field, options[:format])
        output_request(path, options, :get)
      end || 0
    end

    def parse_entry_arguments(args)
      raise Error, "entry accepts ID[,ID...] and optional FIELD; use commas for multiple IDs" if args.length > 2

      ids = args.first.to_s.split(",")
      field = args[1]
      raise Error, "entry accepts comma-separated IDs, not space-separated IDs" if field && entry_id_like?(field)

      [ids, field]
    end

    def entry_id_like?(value)
      value.include?(",") || value.match?(/\A[A-Z0-9_]+(?:\.\d+)?\z/)
    end

    def run_search
      options = common_options.merge(offset: nil, limit: nil, count: false)
      catch(:help) do
        p = parser(options, "Usage: togows search DATABASE QUERY [options]")
        p.on("-o", "--offset N", Integer, "Result offset") { |v| options[:offset] = v }
        p.on("-n", "--limit N", Integer, "Result limit") { |v| options[:limit] = v }
        p.on("--count", "Count results") { options[:count] = true }
        p.parse!(@argv)
        database, query = @argv
        return command_help(:search, "search requires DATABASE and QUERY", 2) if database.nil?
        return command_help(:search, "search requires QUERY after DATABASE", 2) if query.nil?

        validate_search_options(options)
        options[:offset] = 1 if options[:limit] && !options[:offset]

        path = URLBuilder.search(database, query, options[:offset], options[:limit], options[:count], options[:format])
        output_request(path, options, :get)
      end || 0
    end

    def validate_search_options(options)
      if options[:count] && (options[:offset] || options[:limit])
        raise Error, "--count cannot be used with --offset or --limit"
      end

      raise Error, "--offset and --limit must be used together" if options[:offset] && !options[:limit]
    end

    def run_convert
      options = common_options.merge(to: nil)
      catch(:help) do
        p = parser(options, "Usage: togows convert SOURCE.FORMAT [FILE] [options]")
        p.on("--to FORMAT", "Target format") { |v| options[:to] = v }
        p.parse!(@argv)
        source, file = @argv
        return command_help(:convert, "convert requires SOURCE.FORMAT or SOURCE --to FORMAT", 2) if source.nil?

        path = URLBuilder.convert(source, options[:to])
        body = file ? File.read(file) : read_convert_stdin
        output_request(path, options, :post, body)
      end || 0
    end

    def read_convert_stdin
      raise Error, "convert requires FILE or piped stdin; stdin is a terminal" if @stdin.tty?

      @stdin.read
    end

    def run_ucsc
      options = common_options.merge(offset: nil, limit: nil)
      catch(:help) do
        p = parser(options, "Usage: togows ucsc [DATABASE] [TABLE] [QUERY] [options]")
        p.on("-o", "--offset N", Integer, "Result offset") { |v| options[:offset] = v }
        p.on("-n", "--limit N", Integer, "Result limit") { |v| options[:limit] = v }
        p.parse!(@argv)
        raise Error, "--offset and --limit must be used together" if options[:offset] && !options[:limit]
        raise Error, "--offset and --limit must be used together" if options[:limit] && !options[:offset]

        database, table, *query_parts = @argv
        query = query_parts.empty? ? nil : query_parts.join("/")
        path = URLBuilder.ucsc(database, table, query, options[:offset], options[:limit], options[:format])
        output_request(path, options, :get)
      end || 0
    end

    def run_databases
      options = common_options
      catch(:help) do
        parser(options, "Usage: togows databases [entry|search] [options]").parse!(@argv)
        kind = @argv.shift
        raise Error, "databases accepts only one argument: entry or search" unless @argv.empty?

        kinds = if kind.nil?
                  %w[entry search]
                elsif %w[entry search].include?(kind)
                  [kind]
                else
                  return command_help(:databases, "database list must be entry or search", 2)
                end

        output_database_lists(kinds, options)
      end || 0
    end

    def output_request(path, options, method, body = nil)
      if options[:raw_url]
        @stdout.puts URLBuilder.full_url(options[:base_url], path)
        return 0
      end

      client = Client.new(options[:base_url], options[:timeout])
      response = with_status("Fetching...") do
        (method == :post ? client.post(path, body) : client.get(path)).to_s
      end
      write_output(format_response(response, options), options)
      0
    end

    def output_database_lists(kinds, options)
      if options[:raw_url]
        kinds.each { |kind| @stdout.puts URLBuilder.full_url(options[:base_url], URLBuilder.databases(kind)) }
        return 0
      end

      client = Client.new(options[:base_url], options[:timeout])
      responses = with_status("Fetching...") do
        kinds.map { |kind| [kind, client.get(URLBuilder.databases(kind))] }
      end
      responses.each_with_index do |(kind, body), index|
        @stdout.puts if index.positive?
        @stdout.puts "#{kind}:"
        @stdout.write(body)
      end
      @stdout.write("\n")
      0
    end

    def format_response(response, options)
      return response unless options[:pretty]

      JSON.pretty_generate(JSON.parse(response))
    rescue JSON::ParserError
      response
    end

    def version
      @stdout.puts "togows #{VERSION}"
      0
    end

    def help(message, status)
      @stderr.puts message if message
      @stdout.puts color_help(<<~HELP)
        Usage:
          togows entry DATABASE ID[,ID...] [FIELD] [options]
          togows search DATABASE QUERY [options]
          togows convert SOURCE.FORMAT [FILE] [options]
          togows databases [entry|search] [options]
          togows ucsc [DATABASE] [TABLE] [QUERY] [options]

        Commands:
          entry     Retrieve database entries
          search    Search database entries
          convert   Convert data from stdin or FILE
          databases List databases supported by TogoWS
          ucsc      Access TogoWS UCSC API

        Common options:
          -f, --format FORMAT
              --base-url URL
              --timeout SEC
              --raw-url
              --pager
              --pretty
          -h, --help
      HELP
      status
    end

    def help_for(command, status)
      return help(nil, status) if command.nil?

      case command
      when "entry" then command_help(:entry, nil, status)
      when "search" then command_help(:search, nil, status)
      when "convert" then command_help(:convert, nil, status)
      when "databases", "dbs" then command_help(:databases, nil, status)
      when "ucsc" then command_help(:ucsc, nil, status)
      else
        error("unknown command: #{command}")
        help(nil, 2)
      end
    end

    def command_help(command, message, status)
      error(message) if message
      @stdout.puts color_help(Help::COMMANDS.fetch(command))
      status
    end

    def error(message)
      @stderr.puts "#{@err_color.bold('togows:')} #{message}"
    end

    def write_output(response, options)
      output = response.end_with?("\n") ? response : "#{response}\n"
      return @stdout.write(output) unless options[:pager] && @stdout.respond_to?(:tty?) && @stdout.tty?

      command = pager_command
      return @stdout.write(output) if command.empty?

      write_pager(command, output)
    end

    def pager_command
      ENV.fetch("PAGER", "less -R").shellsplit
    end

    def write_pager(command, output)
      IO.popen(command, "w") { |pager| pager.write(output) }
    rescue Errno::EPIPE
      nil
    end

    def with_status(message)
      return yield unless @stderr.respond_to?(:tty?) && @stderr.tty?

      @stderr.print "\r#{message}"
      yield
    ensure
      clear_status(message) if @stderr.respond_to?(:tty?) && @stderr.tty?
    end

    def clear_status(message)
      @stderr.print "\r#{' ' * message.length}\r"
    end

    def color_help(text)
      highlighted = text.gsub(/^(Usage:)/) { @out_color.bold(Regexp.last_match(1)) }
      color_help_headings(highlighted)
    end

    def color_help_headings(text)
      headings = [
        "Next arguments:",
        "Common search databases:",
        "Search options:",
        "Convert options:",
        "Examples:",
        "Commands:",
        "Common options:"
      ]
      pattern = /^(#{Regexp.union(headings)})/
      text.gsub(pattern) { @out_color.bold(Regexp.last_match(1)) }
    end
  end
end
