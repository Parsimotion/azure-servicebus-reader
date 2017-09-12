_ = require "lodash"

require "should"
require "should-sinon"
sinon = require "sinon"

highland = require "highland"
Promise = require "bluebird"

Reader = require "./reader"

describe "Reader", ->

  { stream, reader, clock, processor, service } = {}

  beforeEach ->
    Promise.setScheduler (fn) => setTimeout fn, 0
    service = fetchMessages: sinon.stub()
    reader = new Reader service
    stream = reader.stream()
    clock = sinon.useFakeTimers()
    processor = sinon.stub()
    
  afterEach =>
    clock.restore()
    stream.pause()

  describe "#stream", ->

    { nextStream } = {}

    beforeEach ->
      nextStream = sinon.spy reader, "_scheduleNextStream"

    context "if servicebus is empty", ->

      emptyServiceBus = ->
        service.fetchMessages.returns Promise.resolve []
        stream.each processor

        timeToElapsed: (@time) -> @
        callsToFetchExpected: (@times) -> @
        verify: ->
          clock.tick @time

          processor.should.have.not.been.called()
          nextStream.should.be.have.callCount @times
          service.fetchMessages.should.be.have.callCount @times

      it "should call to fetch once if the sleep time has not elapsed yet", ->
        emptyServiceBus()
          .timeToElapsed 300
          .callsToFetchExpected 1
          .verify()

      it "should call to fetch other time if the time sleep time has elapsed", ->
        emptyServiceBus()
          .timeToElapsed 1010
          .callsToFetchExpected 2
          .verify()

    it "should be call to fetch twice times if retrieve some messages", ->
      service.fetchMessages
        .onFirstCall().returns Promise.resolve [1, 2, 3]
        .onSecondCall().returns Promise.resolve []

      stream.each processor

      clock.tick 300

      processor.should.have.calledThrice()
      service.fetchMessages.should.have.calledTwice()
      nextStream.should.have.calledTwice()

  describe "#run", ->

    { nextStream } = {}

    beforeEach ->
      nextStream = sinon.stub reader, "_scheduleNextStream"

    it "should process a message successful and it should be removed", ->
      message = createMessage()
      service.fetchMessages.returns Promise.resolve [ message ]
      processor.yieldsTo "done"
      nextStream.returns 1000

      reader.run processor
      clock.tick 300

      service.fetchMessages.should.have.calledOnce()
      processor.should.have.calledOnce()
      message.start.should.have.calledOnce()
      message.stop.should.have.calledOnce()
      message.delete.should.have.calledOnce()

    it "should process a message and its fail then it should be not removed", ->
      message = createMessage()
      service.fetchMessages.returns Promise.resolve [ message ]
      processor.yieldsTo "done", new Error
      nextStream.returns 1000

      reader.run processor
      clock.tick 300

      service.fetchMessages.should.have.calledOnce()
      processor.should.have.calledOnce()
      message.start.should.have.calledOnce()
      message.stop.should.have.calledOnce()
      message.delete.should.be.not.called()

createMessage = ->
  body: JSON.stringify { un: "json", CompanyId: 123, ResourceId: 123 }
  brokerProperties:
    MessageId: "el-message-id"
    DeliveryCount: 0
    EnqueuedTimeUtc: "Sat, 05 Nov 2016 16:44:43 GMT"
  start: sinon.spy()
  stop: sinon.spy()
  "delete": sinon.stub().returns Promise.resolve()