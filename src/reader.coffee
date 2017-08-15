_ = require "lodash"
debug = require("debug") "azure-servicebus-reader:reader"
highland = require "highland"


module.exports =
  class Reader

    constructor: (@service, { @logger = console, @concurrency = 25 } = {} ) ->

    run: (processor) ->
      @stream()
      .map (message) =>
        highland (push, next) =>
          message.start()
          context = @_context { message, push }
          processor context, message.body
      .parallel @concurrency
      .each ({ success }) -> debug "Finished message with status #{success}"

    stream: =>
      highland (push, next) =>      
        @service.fetchMessages()
        .then (messages) =>
          push null, message for message in messages
          @_scheduleNextStream messages.length, next
        return

    _context: ({ message, push }) =>
      __callback = (err) -> 
        success = not err?
        message.stop()
        
        $promise = if success then message.delete() else Promise.resolve()

        $promise.then ->
          push null, { success, err, message }
          push null, highland.nil

      { brokerProperties: { EnqueuedTimeUtc, DeliveryCount } } = message

      log: @logger
      bindingData:
        enqueuedTimeUtc: new Date EnqueuedTimeUtc
        deliveryCount: DeliveryCount
      done: __callback

    _scheduleNextStream: (actualAmount, next) =>
      delayToFetch = if actualAmount is 0 then 1000 else 0

      debug "_scheduleFetch in #{delayToFetch}"
      setTimeout =>
        next @stream()
      , delayToFetch