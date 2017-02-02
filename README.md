# Hubot githubfollow

Hubot script for follow github repos and get events notification.
This project is based on polling the REST API so this script can monitor all the public repositories on github without web hooks.
Obviously it isn't the best solution but it offers more possibility without owning the repos.

### Main features
- The bot actually "waits" for stars, push and fork of a repo.
- The bot can manage to be invited in multiple rooms.
- The bot output is formatted in Markdown.

### Things to do:
- [ ] Implement unfollow
- [ ] Use brain(now is all in memory)
- [ ] Implement unit test
- [ ] Use Etag for checking changes
- [ ] Manage multiple changes during the interval


Embrional phase, really raw implementation. For me it was a rxjs workbench

It was in JS and I flash ported in coffee so it's really ugly :smile:


## Installation

This module is installed via npm:

```
npm install --save hubot-githubfollow
```

Add **hubot-githubfollow** to your `external-scripts.json`:

```json
[
  "hubot-githubfollow"
]
```

In order to call github api you have to define `GHF_KEY` environement variable with a valid github Personal access tokens

## Sample Interaction

```
user1>> hubot follow github/hubot
hubot>> Done
```

## NPM Module

[https://www.npmjs.com/package/hubot-githubfollow](https://www.npmjs.com/package/hubot-githubfollow)


## Contributing

Any help is welcome, I don't have a strategy right now.

If you like to help follow this steps for configuring your development environment.

Clone this repository

```
git clone https://github.com/rixlabs/hubot-githubfollow.git
```

To intall all dependencies do:

```
npm install
```

To run tests, type:

```
npm test
```

If you want to try the script inside your hubot do:

Inside the huot-githubfollow directory

```
npm link 
```

Inside your hubot directory type:

```
npm link hubot-githubfollow
```

Add hubot-githufollow to the `external-scripts.json` of your hubot:

```json
[
  "hubot-githubfollow"
]
```

Set the GHF_KEY environment variable

```
export GHF_KEY=<github Personal access tokens>
```

Startup your hubot with:

```
bin/hubot
```

To cleanup after tests, cd to the root of your hubot and type:

```
npm unlink hubot-githubfollow
```

and then cd to the hubot-githubfollow root and do:

```
npm unlink
```

