_ = require "lodash"

require "should"
sinon = require "sinon"
require "should-sinon"
azure = require "azure-sb"
Promise = require "bluebird"
Service = require "./servicebus.service"

serviceOpts =
  connection: {}
  topic: "aTopic"
  subscription: "aSubscription"


createMessage = (resourceId) ->
  body: JSON.stringify { un: "json", CompanyId: 123, ResourceId: resourceId }
  brokerProperties:
    MessageId: "el-message-id"
    DeliveryCount: 0
    EnqueuedTimeUtc: "Sat, 05 Nov 2016 16:44:43 GMT"


describe "ServiceBus - Service", ->

  { service } = {}

  beforeEach ->
    sinon.stub(azure, "createServiceBusService").returns receiveSubscriptionMessageAsync: ->
    service = new Service serviceOpts

  afterEach ->
    azure.createServiceBusService.restore()

  it "fetch messages", ->
    result = _.times 5, createMessage

    stub = sinon.stub(service.service, "receiveSubscriptionMessageAsync").returns Promise.resolve result
    service.fetchMessages()
    .tap -> stub.should.have.calledWithExactly serviceOpts.topic, serviceOpts.subscription, isPeekLock: true
    .tap (messages) -> messages.should.have.an.Array().and.lengthOf 5
    .tap (messages) ->
      messages.should.matchEach ({ body }) -> body.should.be.an.Object()

  it "sanitized", ->
    cleanMessage = createMessage 1
    sanitizedBody = service._sanitize "@strin3http://schemas.microsoft.com/2003/10/Serialization/p#{cleanMessage.body}"
    sanitizedBody.should.be.eql cleanMessage.body