_ = require "lodash"

sinon = require "sinon"
should = require "should"
require "should-sinon"
Promise = require "bluebird"

Reader = require "./reader"

describe "Reader", ->

  { stream, reader, clock } = {}

  beforeEach ->
    Promise.setScheduler (fn) => setTimeout fn, 0
    reader = new Reader
    stream = reader.stream()
    clock = sinon.useFakeTimers()

  afterEach =>
    clock.restore()
    stream.pause()


  it "should be call to fetch once if it retrieve not any message", ->
    stubFetch = sinon.stub(reader, "_fetchMessages").returns Promise.resolve []
    stubNextStream = sinon.stub(reader, "_scheduleNextStream")

    runnerSpy = sinon.spy()
    stream.each runnerSpy

    clock.tick 300
    clock.restore()

    runnerSpy.should.have.not.been.called()
    stubNextStream.should.be.have.calledOnce()
    stubFetch.should.be.have.calledOnce()

