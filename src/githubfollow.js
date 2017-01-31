Rx = require('rxjs/Rx');
rp = require('request-promise');

var key = ''
try {
  key = process.env.GHF_KEY
} catch (e) {
  throw new Error('The environment variable "GHF_KEY" is required');
}


module.exports = (robot) => {
    robot.respond(/follow (.*)/i, (msg) => {
        robot.logger.debug(roomsSubscriptions);

        if(roomsSubscriptions[msg.match[1]] == undefined) {
            robot.logger.debug('NEW REPO -> '+msg.match[1])
            newSub = {subscribers:[msg.envelope.room]};
            roomsSubscriptions[msg.match[1]]=newSub;
        }
        else{
            updateSub = roomsSubscriptions[msg.match[1]];
            if(updateSub.subscribers.indexOf(msg.envelope.room)<= -1){
                updateSub.subscribers.push(msg.envelope.room)
                roomsSubscriptions[msg.match[1]] = updateSub;
            }
        }
        robot.logger.debug(roomsSubscriptions);
        msg.send('Done');
    });

    robot.respond(/unfollow (.*)/i, (msg) => {
        repo = msg.match[1];
        subscriber = msg.envelope.room
        
        msg.send('Done');
    });

    
    function getGHEvents(repo){
        var options = {
            uri: 'https://api.github.com/repos/'+repo+'/events',
            headers: {'Authorization': 'token '+key, 'User-Agent': ''},
            transform: checkETag
            //json: true // Automatically parses the JSON string in the response 
        };
        promise = rp(options)
        function checkETag(body, response, resolveWithFullResponse){
            console.log(response.headers['etag'])
            return JSON.parse(body)
        }
        return Rx.Observable.fromPromise(promise);
    }

    function checkFilter(event){
        console.log('*********'+event+'*********')
        if(lastRposStatus[event.repo.name] != undefined){
            if(event.id != lastRposStatus[event.repo.name].id){
                robot.logger.debug('CHECK -> changed');
                lastRposStatus[event.repo.name] = event;
                return (true && (goodEvents.indexOf(event.type) > -1));
            }
            robot.logger.debug('CHECK -> same shit');
            return false;
        }
        else{
            robot.logger.debug('CHECK -> new repo');
            lastRposStatus[event.repo.name] = event;
            //could be false to avoid first run notifications
            robot.logger.debug('CHECK -> '+(true && (goodEvents.indexOf(event.type) > -1)));
            return (true && (goodEvents.indexOf(event.type) > -1));
        }

    }

    function notifyStream(event){
        robot.logger.debug('NOTIFY -> '+roomsSubscriptions[event.repo.name]);
        robot.logger.debug('NOTIFY -> '+event.id+'  ->  '+event.repo.name)
        roomsSubscriptions[event.repo.name].subscribers.forEach((sub) => {
            envelope = {
                        room: sub,
                        user: "@faina_bot",
                        parse_mode: "Markdown"
                    };
            repoNofification = event.repo.name
            toNotify = notificationTemplate(repoNofification,event)
            //robot.send(envelope,event.id+' - '+event.type)
            robot.logger.debug('NOTIFY -> envelope:'+envelope.room)
            robot.send(envelope,toNotify)
        });
         
    }

    function notificationTemplate(repo,event){
        action = ''
        switch(event.type){
            case 'WatchEvent':
                action = `*${event.actor.login}* starred *${event.repo.name}*`
                break;
            case 'PushEvent':
                action = `*${event.actor.login}* pushed this commits to *${event.repo.name}*:\n`
                event.payload.commits.forEach((commit) => {
                    message = commit.message.match(/Merge pull request #\d/) || commit.message
                    action=action+`- *${commit.author.email}* -> ${message} \n`
                });
                break;
            case 'ForkEvent':
                action = `*${event.actor.login}* forked ${event.repo.name} to ${event.payload.forkee.full_name}`
                break;
            default:
                action = `*${event.repo.name}* - *${event.type}*`
        }

        
        return action
    }

    goodEvents = ['WatchEvent','PushEvent','ForkEvent']


    roomsSubscriptions = {}
    roomsSubscriptions['rixlabs/springboot-sandbox']= { subscribers:['23607009']}
    roomsSubscriptions['rixlabs/mover']= { subscribers:['23607009']}
    roomsSubscriptions['rixlabs/github-sub']= { subscribers:['23607009']}
    //roomsSubscriptions = [];

    const lastRposStatus = {};
    const source = Rx.Observable.timer(0, 30000);

    const giveBackCallObs = source.flatMap(() => 
        Rx.Observable.pairs(roomsSubscriptions)
        .flatMap(sub => getGHEvents(sub[0]))
    );

    giveBackCallObs
        .map(event => event[0])
        .filter(checkFilter)
        .subscribe(notifyStream,err => console.log("ERROR! -> "+err));
  }