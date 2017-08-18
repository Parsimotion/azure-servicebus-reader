_ = require "lodash"
debug = require("debug") "azure-servicebus-reader:locked-message"
highland = require "highland"

module.exports =
  class TouchableMessage

    constructor: (@service, message, opts = {}) ->
      @lockedMessage = message
      _.assign @, message
      @timeToPeek = opts.timeToPeek or process.env.LOCKED_MESSAGE_TIME_TO_PEEK or 30 * 1000

    start: ->
      debug "Starting peek message every #{@timeToPeek} seconds... #{@_id()}"
      @stream = @_stream().flatMap @_touch
      @stream.resume()

    stop: ->
      debug "Stoping peek message... #{@_id()}"
      @stream.done => clearInterval @interval
      @stream.end()

    _touch: =>
      debug "Touching message... #{@_id()}"
      highland @service.renewLockForMessageAsync(@lockedMessage)

    _stream: ->
      highland (push, next) =>
        @interval = setInterval (=> push undefined, 1), @timeToPeek

    _id: => @lockedMessage.brokerProperties?.MessageId
