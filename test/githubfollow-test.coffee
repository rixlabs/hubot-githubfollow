Helper = require('hubot-test-helper')
chai = require 'chai'

expect = chai.expect

helper = new Helper('../src/githubfollow.coffee')

describe 'githubfollow', ->
  beforeEach ->
    @room = helper.createRoom()

  afterEach ->
    @room.destroy()

  it 'responds follow', ->
    @room.user.say('alice', '@hubot follow github/hubot').then =>
      expect(@room.messages).to.eql [
        ['alice', '@hubot follow github/hubot']
        ['hubot', 'Done']
      ]


