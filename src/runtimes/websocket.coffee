Base = require './base'

class WebSocketRuntime extends Base
  constructor: (dataflow, graph) ->
    @connecting = false
    @connection = null
    @protocol = 'noflo'
    @buffer = []
    super dataflow, graph

  sendGraph: (command, payload) ->
    @send 'graph', command, payload
  sendNetwork: (command, payload) ->
    @send 'graph', command, payload
  sendGraph: (command, payload) ->
    @send 'graph', command, payload

  connect: (protocol) ->
    return if @connection or @connecting
    @connection = new WebSocket @getUrl(), @protocol
    @connection.addEventListener 'open', =>
      @connecting = false
      @flush()
    , false
    @connection.addEventListener 'message', @handleMessage, false
    @connection.addEventListener 'error', @handleError, false
    @connection.addEventListener 'close', =>
      @connection = null
    , false
    @connecting = true

  send: (protocol, command, payload) ->
    if @connecting
      @buffer.push
        protocol: protocol
        command: command
        payload: payload
      return

    return unless @connection
    @connection.send JSON.stringify
      protocol: protocol
      command: command
      payload: payload

  disconnect: (protocol) ->
    return unless @connection
    @connection.close()

  getUrl: ->
    return "ws://#{location.hostname}:3569"
    "ws://#{location.hostname}:#{location.port}"

  handleError: (error) =>
    @connection = null
    @connecting = false

  handleMessage: (message) =>
    msg = JSON.parse message.data
    switch msg.protocol
      when 'graph' then @recvGraph msg.command, msg.payload
      when 'network' then @recvNetwork msg.command, msg.payload
      when 'component' then @recvComponent msg.command, msg.payload

  flush: ->
    for item in @buffer
      @send item.protocol, item.command, item.payload
    @buffer = []

module.exports = WebSocketRuntime