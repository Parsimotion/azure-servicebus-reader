_ = require "lodash"

sinon = require "sinon"
should = require "should"
require "should-sinon"
Promise = require "bluebird"

Reader = require "./reader"

describe "Reader", ->

  { stream, reader, clock, nextStreamSpy } = {}

  beforeEach ->
    Promise.setScheduler (fn) => setTimeout fn, 0
    reader = new Reader
    stream = reader.stream()
    nextStreamSpy = sinon.spy reader, "_scheduleNextStream"
    clock = sinon.useFakeTimers()

  afterEach =>
    clock.restore()
    stream.pause()


  context "if servicebus is empty", ->

    emptyServiceBus = ->
      stubFetch = sinon.stub(reader, "_fetchMessages").returns Promise.resolve []
      runnerSpy = sinon.spy()
      stream.each runnerSpy

      timeToElapsed: (@time) -> @
      callsToFetchExpected: (@times) -> @
      verify: ->
        clock.tick @time

        runnerSpy.should.have.not.been.called()
        nextStreamSpy.should.be.have.callCount @times
        stubFetch.should.be.have.callCount @times

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
    stubFetch = sinon.stub(reader, "_fetchMessages")
      .onFirstCall().returns Promise.resolve [1, 2, 3]
      .onSecondCall().returns Promise.resolve []

    runnerSpy = sinon.spy()
    stream.each runnerSpy

    clock.tick 300

    runnerSpy.should.have.calledThrice()
    stubFetch.should.have.calledTwice()
    nextStreamSpy.should.have.calledTwice()


