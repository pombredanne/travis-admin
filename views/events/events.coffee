Travis = Ember.Application.create()
window.Travis = Travis

Travis.Event = Em.Object.extend
  uuid: null
  init: ->
    @_super.apply(this, arguments)

    uuid = @get('uuid')
    Travis.Group.addEvent(uuid, this)

Travis.Group = Em.Object.extend
  init: ->
    @_super.apply(this, arguments)

    @set('events', [])
    Travis.Group.all.addObject(this)

Travis.Group.groupMappings = {}
Travis.Group.all = Ember.ArrayProxy.create
  content: []

Travis.Group.addEvent = (uuid, event) ->
  @groupMappings[uuid] ||= @create(uuid: uuid)
  group = @groupMappings[uuid]
  group.get("events").addObject(event)

Travis.groupsController = Ember.ArrayController.create
  content: Travis.Group.all
  setSelected: (group) ->
    @set('selected', group)

Travis.GroupView = Ember.View.extend
  click: (e) ->
    Travis.groupsController.setSelected(@get('group'))

Travis.EventDetailsView = Ember.View.extend
  contentTag: 'li'
  message: (->
    @getPath('event.message')
  ).property('event.message')
  payload: (->
    JSON.stringify(@getPath('event.payload'))
  ).property('event.payload')

source = new EventSource("events/stream")
source.onmessage = (event) ->
  data = jQuery.parseJSON(event.data)
  Travis.Event.create(data)

