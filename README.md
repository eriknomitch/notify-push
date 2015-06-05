# notify-push
A general purpose popup notifier sender/receiver for using WebSockets (via [Pusher](https://pusher.com)).

## Overview
`notify-push` employs a Receiver (*currently OS X only*) and Sender(s) to push messages from the Sender(s) to the Receiver.


![IRC Example](images/terminal-notifier.png "IRC Example")

**Example Use Case**:
You have `irssi` set up in a `screen` on a remote machine and you want to be notified on your laptop/desktop whenever your name gets highlighted.

## Disclaimer

![Works on my Machine](http://serve.eriknomitch.com/images/works-on-my-machine.jpg "Works on my Machine")

## Installation

### Create Pusher App
Create an App on [Pusher](https://pusher.com) named **notify-push**.  The free account should be plenty.

### Install notify-push
For the Receiver machine and the Sender machine(s):

```Shell
$ gem install notify-push
```

### Create & Distribute Configuration File
Next, create a configuration file with your Pusher App's credentials (found on your Pusher App's page under *App Credentials*) and distribute it to each machine (Receiver and Sender(s)).

**Location**: `~/.notify-pushrc`

#### Example

```YML
pusher:
  key: a1a2a3b1b2b3c1c2c3d1
  secret: a1a2a3b1b2b3c1c3c1d1
  app_id: 12345
```

## Receiver

### Usage
Invoke the Receiver with:

```Shell
$ notify-push --receiver # or -r
```

TODO: There's a .plist launchd file in there but it's not ready.

## Sender

### Usage

```Shell
$ notify-push <message> [title] [subtitle]
```

Alternatively, you can `curl` or use any Pusher tool to send on messages to your `notify-push` app on channel `"notifications"` with data:

```
message:  The message to notify you with in the notifier popup (REQUIRED)
title:    The title of the notifier popup (Optional)
subtitle: The subtitle of the notifier popup (Optional)
```
