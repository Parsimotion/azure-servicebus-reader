_ = require "lodash"

require "should"
require "should-sinon"
sinon = require "sinon"

Promise = require "bluebird"

Reader = require "./reader"

describe "Reader", ->

  { stream, reader, clock, nextStreamSpy, processor, service } = {}

  beforeEach ->
    Promise.setScheduler (fn) => setTimeout fn, 0
    service = fetchMessages: sinon.stub()
    reader = new Reader service
    stream = reader.stream()
    nextStreamSpy = sinon.spy reader, "_scheduleNextStream"
    clock = sinon.useFakeTimers()
    processor = sinon.spy()

  afterEach =>
    clock.restore()
    stream.pause()


  context "if servicebus is empty", ->

    emptyServiceBus = ->
      service.fetchMessages.returns Promise.resolve []
      stream.each processor

      timeToElapsed: (@time) -> @
      callsToFetchExpected: (@times) -> @
      verify: ->
        clock.tick @time

        processor.should.have.not.been.called()
        nextStreamSpy.should.be.have.callCount @times
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
    nextStreamSpy.should.have.calledTwice()
