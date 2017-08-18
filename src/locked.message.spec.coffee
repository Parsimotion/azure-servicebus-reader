require "should"
require "should-sinon"

_ = require "lodash"
highland = require "highland"
sinon = require "sinon"
LockedMessage = require "./locked.message"
Promise = require "bluebird"

describe "LockedMessage", ->

  { message, clock, renewLockForMessageAsync, timeToPeek } = {}

  beforeEach ->
    timeToPeek = 100
    renewLockForMessageAsync = sinon.stub().returns Promise.resolve()
    message = new LockedMessage { renewLockForMessageAsync }, {}, { timeToPeek }
    clock = sinon.useFakeTimers()
    Promise.setScheduler (f) -> setTimeout f, 0
    sinon.stub(highland, "setImmediate").yields()

  afterEach ->
    highland.setImmediate.restore()
    clock.restore()

  it "the peek time hasn't pass", ->
    message.start()
    renewLockForMessageAsync.should.have.not.called()

  it "the peek time has passed once", ->
    message.start()
    clock.tick timeToPeek + 10
    renewLockForMessageAsync.should.have.calledOnce()

  it "when the message is stopped, it stops peeking", ->
    message.start()
    clock.tick timeToPeek + 20
    message.stop()
    clock.tick timeToPeek * 3
    renewLockForMessageAsync.should.have.calledOnce()
