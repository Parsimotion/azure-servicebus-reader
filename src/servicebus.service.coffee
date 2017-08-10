Promise = require "bluebird"
azure = require "azure-sb"

module.exports =
  class ServiceBusService

    constructor: ({ connection, @topic, @subscription }) ->
      @service = Promise.promisifyAll azure.createServiceBusService connection

    fetchMessages: =>
      @service.receiveSubscriptionMessageAsync @topic, @subscription, isPeekLock: true