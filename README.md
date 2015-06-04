# notify-push
A general purpose popup notifier sender/receiver for using WebSockets (via Pusher).

## Sender

### Usage

```Shell
$ notify-push <message> [title] [subtitle]
```

## Receiver

### Configuration File

Location: `~/.notify-pushrc`

#### Example

```YML
pusher:
  key: a1a2a3b1b2b3c1c2c3d1
  secret: a1a2a3b1b2b3c1c3c1d1
  app_id: 12345
```

