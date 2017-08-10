_ = require "lodash"
debug = require("debug") "azure-servicebus-reader"
Promise = require "bluebird"
highland = require "highland"


module.exports =
  class Reader

    construct: ->

    stream: ->
      highland (push, next) =>      
        @_fetchMessages()
        .then (messages) =>
          push null, message for message in messages
          @_scheduleNextStream()
        return

    _fetchMessages: =>
      throw new Error "not implemented"

    _scheduleNextStream: (next) => 
      throw new Error "not implemented"