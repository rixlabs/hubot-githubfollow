# Description:
#   Hubot script for follow github repos and get events notifications 
#
# Dependencies:
#   None outside node dependencies
#
# Configuration:
#   You need to configure the GHF_KEY environement variable to a valid github Personal access tokens
#
# Commands:
#   hubot follow <githubrepo> - start to follow a github repository - eg. github/hubot
#
# Author:
#   rixlabs
#

Rx = require 'rxjs/Rx'
rp = require 'request-promise'


module.exports = (robot) ->
    key = process.env.GHF_KEY
    unless key
        robot.emit 'error', new Error 'The environment variable "GHF_KEY" is required.'
        process.exit(1)

    robot.respond /follow (.*)/i, (msg) ->
        robot.logger.debug(roomsSubscriptions)

        if roomsSubscriptions[msg.match[1]] == undefined
            robot.logger.debug('NEW REPO -> '+msg.match[1])
            newSub = {subscribers:[msg.envelope.room]}
            roomsSubscriptions[msg.match[1]]=newSub
        
        else
            updateSub = roomsSubscriptions[msg.match[1]]
            if updateSub.subscribers.indexOf(msg.envelope.room)<= -1
                updateSub.subscribers.push(msg.envelope.room)
                roomsSubscriptions[msg.match[1]] = updateSub
            
        
        robot.logger.debug(roomsSubscriptions);
        msg.send('Done');
    
    
    getGHEvents = (repo) ->
        options =
            uri: 'https://api.github.com/repos/'+repo+'/events'
            headers: {'Authorization': 'token '+key, 'User-Agent': ''}
            json: true
            
        promise = rp(options)
        
        return Rx.Observable.fromPromise(promise);


    checkFilter = (event) ->
        if lastRposStatus[event.repo.name] != undefined
            if event.id != lastRposStatus[event.repo.name].id
                robot.logger.debug('CHECK -> changed')
                lastRposStatus[event.repo.name] = event
                return (true && (goodEvents.indexOf(event.type) > -1))
            
            robot.logger.debug('CHECK -> same shit')
            return false;
        
        else
            robot.logger.debug('CHECK -> new repo')
            lastRposStatus[event.repo.name] = event
            #could be false to avoid first run notifications
            robot.logger.debug('CHECK -> '+(true && (goodEvents.indexOf(event.type) > -1)))
            return (true && (goodEvents.indexOf(event.type) > -1))
        

    notifyStream = (event) ->
        robot.logger.debug('NOTIFY -> '+roomsSubscriptions[event.repo.name])
        robot.logger.debug('NOTIFY -> '+event.id+'  ->  '+event.repo.name)
        for sub in roomsSubscriptions[event.repo.name].subscribers
            envelope = 
                room: sub,
                user: "@faina_bot"
                parse_mode: "Markdown"

            repoNofification = event.repo.name
            toNotify = notificationTemplate(repoNofification,event)
            #robot.send(envelope,event.id+' - '+event.type)
            robot.logger.debug('NOTIFY -> envelope:'+envelope.room)
            robot.send(envelope,toNotify)


    notificationTemplate = (repo,event) ->
        action = ''
        switch event.type
            when 'WatchEvent'
                action = "*#{event.actor.login}* starred *#{event.repo.name}*"
            when 'PushEvent'
                action = "*#{event.actor.login}* pushed this commits to *#{event.repo.name}*:\n"
                for commit in event.payload.commits
                    message = commit.message.match(/Merge pull request #\d/) || commit.message
                    action=action+"- *#{commit.author.email}* -> #{message} \n"
            when 'ForkEvent'
                action = "*#{event.actor.login}* forked #{event.repo.name} to #{event.payload.forkee.full_name}"
            else
                action = "*#{event.repo.name}* - *#{event.type}*"

        return action
    

    
    goodEvents = ['WatchEvent','PushEvent','ForkEvent']


    roomsSubscriptions = {}
    roomsSubscriptions['rixlabs/hubot-githubfollow']= { subscribers:['Shell']}

    #roomsSubscriptions = [];

    lastRposStatus = {}
    source = Rx.Observable.timer(0, 30000);


    giveBackCallObs = source.flatMap(() -> Rx.Observable.pairs(roomsSubscriptions)).flatMap((sub) -> getGHEvents(sub[0]))
    

    giveBackCallObs.map((event) -> event[0]).filter(checkFilter).subscribe(notifyStream,(err) -> console.log("ERROR! -> "+err))


