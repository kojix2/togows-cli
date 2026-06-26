# frozen_string_literal: true

require_relative "test_helper"

class TestCLI < Minitest::Test
  class TTYInput
    def tty?
      true
    end
  end

  class TTYStringIO < StringIO
    def tty?
      true
    end
  end

  class ConvertClient
    attr_reader :posted_body

    def get(_path)
      "ok"
    end

    def post(_path, body)
      @posted_body = body
      "converted"
    end
  end

  class DatabaseClient
    def get(path)
      "#{path}\n"
    end
  end

  def run_cli(argv, stdin: StringIO.new, stdout: StringIO.new, stderr: StringIO.new)
    out = stdout
    err = stderr
    status = TogoWS::CLI.new(argv, stdin, out, err).run
    [status, out.string, err.string]
  end

  def test_version
    status, out, err = run_cli(["--version"])
    assert_equal 0, status
    assert_equal "togows #{TogoWS::VERSION}\n", out
    assert_equal "", err
  end

  def test_top_level_help_option
    status, out, err = run_cli(["--help"])
    assert_equal 0, status
    assert_match(/Usage:/, out)
    assert_equal "", err
  end

  def test_top_level_short_help_option
    status, out, err = run_cli(["-h"])
    assert_equal 0, status
    assert_match(/Usage:/, out)
    assert_equal "", err
  end

  def test_entry_raw_url
    status, out, err = run_cli(["entry", "pubmed", "20472643", "authors", "--format", "json", "--raw-url"])
    assert_equal 0, status
    assert_equal "https://togows.org/entry/pubmed/20472643/authors.json\n", out
    assert_equal "", err
  end

  def test_entry_multiple_ids_must_be_comma_separated
    status, out, err = run_cli(%w[entry pubmed 123 456 --raw-url])
    assert_equal 2, status
    assert_equal "", out
    assert_match(/comma-separated IDs/, err)
  end

  def test_entry_rejects_too_many_positionals
    status, out, err = run_cli(%w[entry pubmed 123 456 seq --raw-url])
    assert_equal 2, status
    assert_equal "", out
    assert_match(/optional FIELD/, err)
  end

  def test_entry_comma_separated_ids_still_work
    status, out, err = run_cli(["entry", "pubmed", "123,456", "authors", "--raw-url"])
    assert_equal 0, status
    assert_equal "https://togows.org/entry/pubmed/123%2C456/authors\n", out
    assert_equal "", err
  end

  def test_search_raw_url
    status, out, err = run_cli(["search", "uniprot", "lung cancer", "-o", "1", "-n", "10", "--raw-url"])
    assert_equal 0, status
    assert_equal "https://togows.org/search/uniprot/lung+cancer/1,10\n", out
    assert_equal "", err
  end

  def test_search_limit_defaults_offset_to_one
    status, out, err = run_cli(["search", "uniprot", "FGF19", "--limit", "10", "--raw-url"])
    assert_equal 0, status
    assert_equal "https://togows.org/search/uniprot/FGF19/1,10\n", out
    assert_equal "", err
  end

  def test_convert_raw_url
    status, out, err = run_cli(["convert", "genbank.gff", "--raw-url"])
    assert_equal 0, status
    assert_equal "https://togows.org/convert/genbank.gff\n", out
    assert_equal "", err
  end

  def test_convert_without_file_rejects_terminal_stdin
    status, out, err = run_cli(["convert", "genbank.gff"], stdin: TTYInput.new)
    assert_equal 2, status
    assert_equal "", out
    assert_match(/requires FILE or piped stdin/, err)
  end

  def test_convert_with_piped_stdin
    client = ConvertClient.new
    stdin = StringIO.new("LOCUS")
    status = nil
    out = nil
    err = nil

    stub_method(TogoWS::Client, :new, client) do
      status, out, err = run_cli(["convert", "genbank.gff"], stdin: stdin)
    end

    assert_equal 0, status
    assert_equal "converted\n", out
    assert_equal "", err
    assert_equal "LOCUS", client.posted_body
  end

  def test_fetching_status_goes_to_tty_stderr
    client = ConvertClient.new
    status = nil
    out = nil
    err = nil

    stub_method(TogoWS::Client, :new, client) do
      status, out, err = run_cli(
        %w[entry pubmed 1],
        stderr: TTYStringIO.new
      )
    end

    assert_equal 0, status
    assert_equal "ok\n", out
    assert_match(/Fetching\.\.\./, err)
  end

  def test_pager_option_is_ignored_when_stdout_is_not_tty
    client = ConvertClient.new
    status = nil
    out = nil
    err = nil

    stub_method(TogoWS::Client, :new, client) do
      status, out, err = run_cli(%w[entry pubmed 1 --pager])
    end

    assert_equal 0, status
    assert_equal "ok\n", out
    assert_equal "", err
  end

  def test_empty_pager_falls_back_to_stdout
    client = ConvertClient.new
    status = nil
    out = nil
    err = nil

    with_env("PAGER" => "") do
      stub_method(TogoWS::Client, :new, client) do
        status, out, err = run_cli(
          %w[entry pubmed 1 --pager],
          stdout: TTYStringIO.new
        )
      end
    end

    assert_equal 0, status
    assert_equal "ok\n", out
    assert_equal "", err
  end

  def test_pager_epipe_is_success
    client = ConvertClient.new
    status = nil
    out = nil
    err = nil

    with_env("PAGER" => "cat") do
      stub_method(TogoWS::Client, :new, client) do
        stub_method(IO, :popen, ->(_command, _mode) { raise Errno::EPIPE }) do
          status, out, err = run_cli(
            %w[entry pubmed 1 --pager],
            stdout: TTYStringIO.new
          )
        end
      end
    end

    assert_equal 0, status
    assert_equal "", out
    assert_equal "", err
  end

  def test_database_status_keeps_stdout_separate
    status = nil
    out = nil
    err = nil

    stub_method(TogoWS::Client, :new, DatabaseClient.new) do
      status, out, err = run_cli(
        ["databases"],
        stderr: TTYStringIO.new
      )
    end

    assert_equal 0, status
    assert_equal "entry:\n/entry\n\nsearch:\n/search\n\n", out
    assert_match(/Fetching\.\.\./, err)
  end

  def test_ucsc_raw_url
    status, out, err = run_cli(["ucsc", "hg38", "refGene", "name2=UVSSA", "--raw-url"])
    assert_equal 0, status
    assert_equal "https://togows.org/api/ucsc/hg38/refGene/name2%3DUVSSA\n", out
    assert_equal "", err
  end

  def test_databases_raw_url
    status, out, err = run_cli(["databases", "--raw-url"])
    assert_equal 0, status
    assert_equal "https://togows.org/entry\nhttps://togows.org/search\n", out
    assert_equal "", err
  end

  def test_databases_entry_raw_url
    status, out, err = run_cli(["databases", "entry", "--raw-url"])
    assert_equal 0, status
    assert_equal "https://togows.org/entry\n", out
    assert_equal "", err
  end

  def test_search_requires_offset_and_limit_together
    status, _out, err = run_cli(["search", "uniprot", "lung cancer", "--offset", "1", "--raw-url"])
    assert_equal 2, status
    assert_match(/--offset and --limit must be used together/, err)
  end

  def test_search_count_rejects_offset_and_limit
    status, _out, err = run_cli(["search", "uniprot", "lung cancer", "--count", "--offset", "1", "--limit", "10"])
    assert_equal 2, status
    assert_match(/--count cannot be used with --offset or --limit/, err)
  end

  def test_unknown_command
    status, out, err = run_cli(["nope"])
    assert_equal 2, status
    assert_match(/unknown command/, err)
    assert_match(/Usage:/, out)
  end

  def test_entry_without_arguments_shows_contextual_help
    status, out, err = run_cli(["entry"])
    assert_equal 2, status
    assert_match(/entry requires DATABASE and ID/, err)
    assert_match(/Next arguments:/, out)
    assert_match(/togows entry pubmed 20472643 authors/, out)
  end

  def test_help_for_command
    status, out, err = run_cli(%w[help search])
    assert_equal 0, status
    assert_equal "", err
    assert_match(/Usage: togows search DATABASE QUERY/, out)
    assert_match(/togows databases search/, out)
    assert_match(/pubmed/, out)
    assert_match(/--count/, out)
  end

  def test_search_without_arguments_shows_database_hint
    status, out, err = run_cli(["search"])
    assert_equal 2, status
    assert_match(/search requires DATABASE and QUERY/, err)
    assert_match(/togows databases search/, out)
    assert_match(/Common search databases:/, out)
  end

  def test_search_without_query_shows_query_hint
    status, out, err = run_cli(%w[search pubmed])
    assert_equal 2, status
    assert_match(/search requires QUERY after DATABASE/, err)
    assert_match(/QUERY/, out)
    assert_match(/togows search pubmed/, out)
  end

  def test_help_for_databases
    status, out, err = run_cli(%w[help databases])
    assert_equal 0, status
    assert_equal "", err
    assert_match(/Usage: togows databases/, out)
    assert_match(/entry/, out)
    assert_match(/search/, out)
  end

  private

  def with_env(values)
    previous = values.keys.to_h { |key| [key, ENV.fetch(key, nil)] }
    values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
