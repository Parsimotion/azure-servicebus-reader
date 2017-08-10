_ = require "lodash"

require "should"
sinon = require "sinon"
require "should-sinon"
azure = require "azure-sb"
Promise = require "bluebird"
Service = require "./servicebus.service"

describe "ServiceBus - Service", ->

  { service } = {}
  serviceOpts =
    connection: {}
    topic: "aTopic"
    subscription: "aSubscription"

  beforeEach ->
    sinon.stub(azure, "createServiceBusService").returns receiveSubscriptionMessageAsync: ->
    service = new Service serviceOpts

  afterEach ->
    azure.createServiceBusService.restore()

  it "fetch messages", ->
    result = _.times 5, _.identity

    stub = sinon.stub(service.service, "receiveSubscriptionMessageAsync").returns Promise.resolve result
    service.fetchMessages()
    .tap -> stub.should.have.calledWithExactly serviceOpts.topic, serviceOpts.subscription, isPeekLock: true
    .tap (messages) -> messages.should.have.an.Array().and.lengthOf 5