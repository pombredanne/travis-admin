require 'travis/admin/controller'

module Travis::Admin
  class RepoController < Travis::Admin::Controller
    set prefix: '/repo', title: "Repo Admin"

    def alert_for_status(status)
      case status
      when 'unused' then 'alert-warning'
      when 'ok'     then 'alert-success'
      else               'alert-error'
      end
    end

    def new_hook(name, config = {})
      { "config" => config, "events" => settings.services[name][:default_events], "name" => name, 'new' => true, 'active' => true }
    end

    def service_for(hook)
      schema = hook['config'] ? hook['config'].keys.map { |key| ['string', key] } : []
      settings.services[hook['name']] || {
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
      as_user @login

      @repo  = gh["/repos/#{@repo_name}"]
      @hooks = gh["/repos/#{@repo_name}/hooks"]
      slim :index
    end

    post "/add_hook" do
      with_token params[:token]
      @repo_name = params[:repo_name]
      @repo  = gh["/repos/#{@repo_name}"]
      slim :hook, locals: { hook: new_hook(params[:name]) }
    end

    post '/create_hook' do
      with_token params[:token]
      gh.post "/repos/#{params[:repo_name]}/hooks", hook_payload
      flash :success, '**Success**: New hook created!'
    end

    post '/delete_hook' do
      with_token params[:token]
      gh.delete params[:hook]
      flash :success, "**Success**: Destroyed GitHub hook."
    end

    post '/update_hook' do
      with_token params[:token]
      gh.patch params[:hook], hook_payload
      flash :success, "**Success**: Updated GitHub hook."
    end

    post '/test_hook' do
      with_token params[:token]
      gh.post params[:hook] + '/test', hook_payload
      flash :success, "**Success**: Test payload sent."
    end
  end
end
