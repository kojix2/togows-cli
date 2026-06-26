# frozen_string_literal: true

require "uri"

module TogoWS
  module URLBuilder
    module_function

    def entry(database, ids, field = nil, format = nil)
      id_list = Array(ids).join(",")
      parts = ["entry", escape_segment(database), escape_segment(id_list)]
      parts << escape_path(field) if field && !field.empty?
      with_format("/#{parts.join('/')}", format)
    end

    def search(database, query, offset = nil, limit = nil, count = false, format = nil)
      parts = ["search", escape_segment(database), escape_segment(query)]
      if count
        parts << "count"
      elsif offset && limit
        parts << "#{offset},#{limit}"
      end
      with_format("/#{parts.join('/')}", format)
    end

    def convert(source, format = nil)
      data_source, target_format = split_source_format(source, format)
      "/convert/#{escape_segment(data_source)}.#{escape_segment(target_format)}"
    end

    def databases(kind)
      case kind
      when "entry" then "/entry"
      when "search" then "/search"
      else
        raise Error, "database list must be entry or search"
      end
    end

    def ucsc(database = nil, table = nil, query = nil, offset = nil, limit = nil, format = nil)
      parts = %w[api ucsc]
      parts << escape_segment(database) if database && !database.empty?
      parts << escape_segment(table) if table && !table.empty?
      parts << escape_path(query) if query && !query.empty?
      parts << "#{offset},#{limit}" if offset && limit
      with_format("/#{parts.join('/')}", format)
    end

    def full_url(base_url, path)
      base = base_url.to_s.sub(%r{/*\z}, "")
      base + path
    end

    def escape_segment(value)
      URI.encode_www_form_component(value.to_s)
    end

    def escape_path(value)
      value.to_s.split("/", -1).map { |part| escape_segment(part) }.join("/")
    end

    def with_format(path, format)
      return path if format.nil? || format.empty?

      "#{path}.#{escape_segment(format)}"
    end

    def split_source_format(source, format)
      if format && !format.empty?
        [source, format]
      elsif source.to_s.include?(".")
        source.to_s.split(".", 2)
      else
        raise Error, "missing target format; use SOURCE.FORMAT or --to FORMAT"
      end
    end
  end
end
