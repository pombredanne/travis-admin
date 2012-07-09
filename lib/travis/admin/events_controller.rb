require 'travis/admin/controller'
require 'thread'
require 'gh'
require 'timeout'

module Travis::Admin
  class EventsController < Travis::Admin::Controller
    set prefix: '/events', title: 'Event Monitor'

    get '/' do
      slim :index
    end

    get '/events.js' do
      coffee :events
    end

    def background(&block)
      stream(:keep_open) do |out|
        thread = Thread.new { block[out] }
        thread.abort_on_exception = true if settings.development?
        out.callback do
          Thread.new do
            Timeout.timeout(10) do
              redis.punsubscribe rescue nil
              redis.unsubscribe  rescue nil
            end rescue nil
            thread.kill
          end
        end
      end
    end

    def subscribe(uuid = params[:uuid])
      sub, msg = uuid ? [:subscribe, :message] : [:psubscribe, :pmessage]
      redis.public_send(sub, "events:#{uuid || '*'}") do |on|
        on.public_send(msg) { |*, message| yield(message); sleep(0.1) }
      end
    end

    def event(msg)
      event = msg.to_s.lines.map { |l| "data: #{l}" }.join
      event << "\n" unless event.end_with? "\n"
      event << "\n"
    end

    get '/stream' do
      content_type "text/event-stream"
      background { |out| subscribe { |msg| out << event(msg) } }
    end

    private

    class HandlebarsTemplate < Tilt::Template
      def prepare
        hash = "TILT#{data.hash.abs}"
        name = options[:name] ? %( data-template-name="#{name}") : nil
        source = %(<script type="text/x-handlebars"#{name}>#{data}</script>)
        @code = "<<#{hash}.chomp\n#{source}\n#{hash}"
      end

      def precompiled_template(locals)
        @code
      end

      def precompiled(locals)
        source, offset = super
        [source, offset + 1]
      end
    end

    Tilt.register HandlebarsTemplate, :hbs

    def handlebars(path)
      render :hbs, :events
    end
  end
end
