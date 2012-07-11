require 'travis/admin/controller'
require 'gh'

module Travis::Admin
  class GHController < Travis::Admin::Controller
    set prefix: '/gh', title: 'GH Console'

    helpers do
      include GH::Case
      def display_response(response, indentation = 0, key = nil)
        key ||= params[:key].empty? ? "" : " " + params[:key]
        case response
        when nil                  then 'null'
        when respond_to(:to_hash) then display_hash(response.to_hash, indentation, key)
        when respond_to(:to_ary)  then display_array(response.to_a, indentation, key)
        else response.inspect
        end
      end

      def display_list(list, sep1, sep2, indentation, key)
        return "#{sep1} #{sep2}" if list.empty?
        lines = list.each_with_index.map do |*args|
          out = "  " * (indentation + 1)
          out << yield(*args)
        end

        if lines.size == 1 and lines.first.size < 80
          "#{sep1} #{lines.first.gsub(/^ +/, '') } #{sep2}"
        else
          "#{sep1} #{"//" + key unless key.empty?}\n" << lines.join(",\n")<< "\n" << "  " * indentation << sep2
        end
      end

      def display_array(array, indentation, key)
        display_list(array, '[', ']', indentation, key) do |value, index|
          display_response(value, indentation + 1, "#{key} #{index}")
        end
      end

      def display_hash(hash, indentation, key)
        display_list(hash, '{', '}', indentation, key) do |(subkey, value), index|
          subkey.inspect + ": " + display_response(value, indentation + 1, "#{key} #{subkey}")
        end
      end

      def access_key(data, sub = nil, *rest)
        return data unless sub
        return access_key(data, *rest) if sub.empty?

        if sub == "_"
          data.map { |entry| access_key(entry, *rest) }
        else
          sub = Integer sub if sub =~  /^\d+$/
          access_key(data[sub], *rest)
        end
      end
    end

    get '/' do
      @events = []

      if params[:command] and not params[:command].empty?
        as_user params[:user] unless params[:user].to_s.empty?
        gh.instrumenter = proc do |event, payload, &block|
          @events << payload if event == "http.gh"
          block.call
        end
        @output = gh[params[:command]]
        @output = access_key(@output, *params[:key].to_s.split(/\W/))

        if @output["type"] == "file" and @output["encoding"] == "base64" and @output["content"]
          @content = @output["content"].to_s.unpack('m').first
          @lang    = @output["path"].to_s[/[^\.]*$/]
        end
      end

      slim :index
    end
  end
end
