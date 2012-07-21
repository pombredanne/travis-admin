Travis = Ember.Application.create()
window.Travis = Travis

Travis.Event = Em.Object.extend
  uuid: null
  init: ->
    @_super.apply(this, arguments)

    uuid = @get('uuid')
    Travis.Group.addEvent(uuid, this)
  titleBinding: 'message'
  stringifiedPayload: (->
    JSON.stringify(@get('payload'))
  ).property('payload')
  match: (regexp) ->
    payload = @get('stringifiedPayload')
    regexp.test(payload + @get('title') + @get('message'))

Travis.Event.createFromData = (data) ->
  klass = switch data.message
    when 'travis.hub.handler.request.push.handle:received' then Travis.Event.PushReceived
    when 'travis.hub.handler.request.pull_request.handle:received' then Travis.Event.PullRequestReceived
    when 'travis.hub.handler.sync.handle:received' then Travis.Event.SyncRequest
    when 'travis.hub.handler.job.update:received' then Travis.Event.UpdateJob
    when 'travis.event.handler.pusher.notify:received' then Travis.Event.Notify
    else Travis.Event

  klass.create(data)

Travis.Event.GithubEvent = Travis.Event.extend
  repository: ( ->
    repo = @getPath('payload.data.repository')
    owner = repo.owner.name || repo.owner.login
    "#{owner}/#{repo.name}"
  ).property('payload')

Travis.Event.PushReceived = Travis.Event.GithubEvent.extend
  title: (->
    "Push to #{@get('repository')}"
  ).property('repository')

Travis.Event.PullRequestReceived = Travis.Event.GithubEvent.extend
  title: (->
    "Pull request for #{@get('repository')}"
  ).property('repository')

Travis.Event.Notify = Travis.Event.extend
  title: (->
    "Notify #{@get('objectType')}##{@get('objectId')}: #{@get('event')}"
  ).property('objectType', 'objectId', 'event')
  objectTypeBinding: 'payload.object_type'
  objectIdBinding: 'payload.object_id'
  eventBinding: 'payload.event'

Travis.Event.UpdateJob = Travis.Event.extend
  title: (->
    "Update job ##{@get('jobId')}: #{@get('event')}"
  ).property('job_id', 'event')
  jobIdBinding: 'payload.payload.id'
  eventBinding: 'payload.event'

Travis.Event.SyncRequest = Travis.Event.extend
  title: (->
    "Sync request for #{@get('userId')}"
  ).property('userId')
  userIdBinding: 'payload.user_id'

Travis.Group = Em.Object.extend
  init: ->
    @_super.apply(this, arguments)

    @set('events', [])
    Travis.Group.all.unshiftObject(this)
  title: ( ->
    if event = @get('events').objectAt(0)
      event.get('title')
  ).property('events.@each')
  match: (string) ->
    !!@get('events').find (event) -> event.match(string)

Travis.Group.groupMappings = {}
Travis.Group.all = Ember.ArrayProxy.create
  content: []

Travis.Group.addEvent = (uuid, event) ->
  @groupMappings[uuid] ||= @create(uuid: uuid)
  group = @groupMappings[uuid]
  group.get('events').pushObject(event)
  event.set('group', group)

Travis.groupsController = Ember.ArrayController.create
  content: Travis.Group.all

Travis.eventDetailsController = Em.Object.create
  setEvent: (event) ->
    @set('event', event)

Travis.GroupView = Ember.View.extend
  groupBinding: 'content'
  countBinding: 'group.events.length'
  toggleEvents: ->
    this.$('.events').toggle()
  classNameBindings: ['visible']
  classNames: 'group'
  visible: ( ->
    @get('group').match(new RegExp(@get('filter'), 'i'))
  ).property('filter')
  filterBinding: 'Travis.filterWith'

Travis.GroupsList = Em.CollectionView.extend
  itemViewClass: Travis.GroupView
  tagName: 'ul'
  classNames: 'span4 groups'
  contentBinding: 'Travis.groupsController.content'

Travis.EventsList = Em.CollectionView.extend
  classNames: 'events'
  tagName: 'ul'
  itemViewClass: Em.View.extend
  # It's to slow, I need to make filtering better
  #  highlighted: (->
  #    filter = @get("filter")
  #    if filter && filter != ''
  #      @get('event').match(new RegExp(@get('filter'), 'i'))
  #  ).property('filter')
    filterBinding: 'Travis.filterWith'
    classNameBindings: ["highlighted"]
    messageBinding: 'event.message'
    eventBinding: 'content'
    showDetails: ->
      event = @get('event')
      Travis.eventDetailsController.setEvent(event)

Travis.EventDetailsView = Ember.View.extend
  contentTag: 'li'
  eventBinding: 'Travis.eventDetailsController.event'
  message: (->
    @getPath('event.message')
  ).property('event.message')
  payload: (->
    JSON.stringify(@getPath('event.payload'))
  ).property('event.payload')

Travis.FilterView = Em.TextField.extend
  filter: (->
    Travis.set('filterWith', @get('value'))
  ).observes('value')
  placeholder: "filter"
  type: 'search'
  attributeBindings: ['type']
  classNames: ["filter"]

source = new EventSource("events/stream")
source.onmessage = (event) ->
  data = jQuery.parseJSON(event.data)
  Travis.Event.createFromData(data)
