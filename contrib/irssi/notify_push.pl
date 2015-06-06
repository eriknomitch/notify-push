use strict;
use vars qw($VERSION %IRSSI);

%IRSSI = (
    authors	=> "Erik Nomitch",
    contact	=> "erik\@nomitch.com",
    name	=> "notify_push",
    description	=> "An irssi plugin to activate notify-push",
    license	=> "GPL-2",
    url		=> "https://github.com/eriknomitch/notify-push",
);

use Irssi;

sub notify_push {
    my ($server, $msg, $nick, $nick_addr, $target) = @_;

    # WARNING: UNFINISHED - EDIT IN YOUR OWN CHANNELS
    
    # FIX: User-defined channels.
    # Only operate in these channels...
    if ($target =~ m/#(?:foo|bar|baz)/) { 
        system "shell-notify-push", $msg, "IRC", "${nick} says..."
    }
}

Irssi::signal_add_last("message public", "notify_push");
