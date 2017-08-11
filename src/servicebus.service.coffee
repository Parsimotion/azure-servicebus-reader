Promise = require "bluebird"
azure = require "azure-sb"
_ = require "lodash"

module.exports =
  class ServiceBusService

    constructor: ({ connection, @topic, @subscription }) ->
      @service = Promise.promisifyAll azure.createServiceBusService connection

    fetchMessages: =>
      @service.receiveSubscriptionMessageAsync @topic, @subscription, isPeekLock: true
      .map (message) => _.update message, "body", _.flow(@_sanitize, JSON.parse)

    _sanitize: (body) ->
      # The messages come with shit before the "{" that breaks JSON.parse =|
      # Example: @strin3http://schemas.microsoft.com/2003/10/Serialization/p{"Changes":[{"Key":
      # ... (rest of the json) ... *a bunch of non printable characters*
      body
        .substring body.indexOf('{"')
        .replace /[^\x20-\x7E]+/g, ""
