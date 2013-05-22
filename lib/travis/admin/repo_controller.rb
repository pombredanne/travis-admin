require 'travis/admin/controller'
require 'travis/admin/services'

module Travis::Admin
  class RepoController < Travis::Admin::Controller
    set title: "Repo Admin"

    def alert_for_status(status)
      case status
      when 'unused' then 'alert-warning'
      when 'ok'     then 'alert-success'
      else               'alert-error'
      end
    end

    def new_hook(name, config = {})
      { "config" => config, "events" => Services[name][:default_events], "name" => name, 'new' => true, 'active' => true }
    end

    def service_for(hook)
      schema = hook['config'] ? hook['config'].keys.map { |key| ['string', key] } : []
      Services[hook['name']] || {
        title:          hook['name'].to_s,
        events:         Array(hook['events']),
        default_events: Array(hook['events']),
        schema:         Array(schema)
      }
    end

    def hook_payload
      { config: params[:config], name: params[:name], events: params[:events], active: !!params[:active] }
    end

    get '/' do
      slim :index
    end

    post '/' do
      page = request.path_info + params[:repo]
      page += "?user=#{params[:user]}" unless params[:user].to_s.empty?
      redirect to(page)
    end

    get '/:owner/:repo' do
      @login     = params[:user] || params[:owner]
      @repo_name = params[:owner] + '/' + params[:repo]

      as_user @login do
        @repo  = GH["/repos/#{@repo_name}"]
        @hooks = GH["/repos/#{@repo_name}/hooks"]
      end

      slim :index
    end

    post "/add_hook" do
      with_token params[:token] do
        @repo_name = params[:repo_name]
        @repo  = GH["/repos/#{@repo_name}"]
      end

      slim :hook, locals: { hook: new_hook(params[:name]) }
    end

    post '/create_hook' do
      with_token params[:token] do
        GH.post "/repos/#{params[:repo_name]}/hooks", hook_payload
      end

      flash :success, '**Success**: New hook created!'
    end

    post '/delete_hook' do
      with_token params[:token] do
        GH.delete params[:hook]
      end

      flash :success, "**Success**: Destroyed GitHub hook."
    end

    post '/update_hook' do
      with_token params[:token] do
        GH.patch params[:hook], hook_payload
      end

      flash :success, "**Success**: Updated GitHub hook."
    end

    post '/test_hook' do
      with_token params[:token] do
        GH.post params[:hook] + '/test', hook_payload
      end

      flash :success, "**Success**: Test payload sent."
    end
  end
end
