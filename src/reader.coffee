_ = require "lodash"
debug = require("debug") "azure-servicebus-reader"
Promise = require "bluebird"
highland = require "highland"


module.exports =
  class Reader

    construct: ->

    stream: =>
      highland (push, next) =>      
        @_fetchMessages()
        .then (messages) =>
          push null, message for message in messages
          @_scheduleNextStream messages.length, next
        return

    _fetchMessages: =>
      throw new Error "not implemented"

    _scheduleNextStream: (actualAmount, next) =>
      delayToFetch = if actualAmount is 0 then 1000 else 0

      debug "_scheduleFetch in #{delayToFetch}"
      setTimeout =>
        next @stream()
      , delayToFetch