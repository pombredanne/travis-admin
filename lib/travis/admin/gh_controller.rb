require 'travis/admin/controller'
require 'gh'

module Travis::Admin
  class GHController < Travis::Admin::Controller
    class WithLink < Struct.new(:string, :link); end
    set prefix: '/gh', title: 'GH Console'

    helpers do
      include GH::Case

      def linkify(src)
        pattern = url('')
        src.gsub(%r{https://api.github.com/((?:(?!&quot;)\S)+)}) do |content|
          "<a href='#{url_for($1)}'>#{conten}</a>"
        end
      end

      def url_for(options)
        options[:command] ||= params[:command]
        options[:user]    ||= params[:user]
        Addressable::URI.new(query_values: options).to_s
      end

      def display_response(response, indentation = 0, key = nil)
        key ||= params[:key].to_s.empty? ? "" : " " + params[:key]
        case response
        when nil                  then 'null'
        when respond_to(:to_hash) then display_hash(response.to_hash, indentation, key)
        when respond_to(:to_ary)  then display_array(response.to_a, indentation, key)
        when respond_to(:to_str)  then display_string(response.to_s)
        when respond_to(:link)    then display_string(response.string, response.link)
        else h(response.inspect)
        end
      end

      def display_string(string, url = string)
        case url
        when %r{^https://api.github.com/([^"\s]+)$} then "&quot;<a href='#{url_for(command: $1)}'>#{shorten string}</a>&quot;"
        when %r{^https?://([^"\s]+)$} then "&quot;<a href='#{url}'>#{shorten string}</a>&quot;"
        else h(string.inspect)
        end
      end

      def shorten(str)
        return str if str.size < 60
        str[0,57] + '...'
      end

      def display_list(list, sep1, sep2, indentation, key)
        return h("#{sep1} #{sep2}") if list.empty?
        lines = list.each_with_index.map do |*args|
          out = "  " * (indentation + 1)
          out << yield(*args)
        end

        if lines.size == 1 and lines.first.size < 80
          "#{h(sep1)} #{lines.first.gsub(/^ +/, '') } #{h(sep2)}"
        else
          "#{h(sep1)} #{key_link(key)}\n" << lines.join(",\n")<< "\n" << "  " * indentation << h(sep2)
        end
      end

      def key_link(key)
        key = key.to_s.strip
        "// <a href='#{url_for(key: key)}'>#{h key}</a>" unless key.empty?
      end

      def display_array(array, indentation, key)
        display_list(array, '[', ']', indentation, key) do |value, index|
          display_response(value, indentation + 1, "#{key} #{index}")
        end
      end

      def display_hash(hash, indentation, key)
        display_list(hash, '{', '}', indentation, key) do |(subkey, value), index|
          h(subkey.inspect + ": ") + display_response(value, indentation + 1, "#{key} #{subkey}")
        end
      end

      def access_key(data, sub = nil, *rest)
        return data unless sub
        return access_key(data, *rest) if sub.empty?

        if sub == "_"
          data.map { |entry| access_key(entry, *rest) }
        else
          sub    = Integer sub if sub =~  /^\d+$/
          nested = data[sub]

          @url   = data["_links"]['self'] rescue @url
          @url   = @url['href'] if @url.respond_to? :to_hash

          if @url and nested.respond_to? :to_str and not nested =~ %r{^https?://([^"\s]+)$}
            nested = WithLink.new(nested, @url)
            @url   = nil
          end

          access_key(nested, *rest)
        end
      end
    end

    get '/' do
      @events = []

      if params[:command] and not params[:command].empty?
        gh = params[:user].to_s.empty? ? GH.with({}) : as_user(params[:user])
        gh.instrumenter = proc do |event, payload, &block|
          @events << payload if event == "http.gh"
          block.call
        end

        @resource = gh[params[:command]]
        @output   = access_key(@resource, *params[:key].to_s.split(/\W/))

        if @output.respond_to?(:to_hash) and @output["type"] == "file" and @output["encoding"] == "base64" and @output["content"]
          @content = @output["content"].to_s.unpack('m').first
          @lang    = @output["path"].to_s[/[^\.]*$/]
        end
      end

      slim :index
    end
  end
end
