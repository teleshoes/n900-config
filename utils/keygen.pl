#!/usr/bin/perl
use strict;
use warnings;
chdir `echo -n ~/.ssh`;

sub keygen($){
  my $user = shift;
  my $genCmd =
    "mkdir -p ~/.ssh;" .
    "chmod go-w ~/.ssh;" .
    "rm ~/.ssh/*;" .
    "ssh-keygen -t rsa -N \"\" -q -f ~/.ssh/id_rsa;" .
    "mv ~/.ssh/id_rsa.pub ~/.ssh/n900.pub;";
  system "ssh $user@`n900` '$genCmd'";
  system "scp $user@`n900`:~/.ssh/n900.pub .";
  system "scp *.pub $user@`n900`:~/.ssh";

  system "ssh $user@`n900` 'cat ~/.ssh/*.pub > ~/.ssh/authorized_keys'";
}


print "add a user password so we dont have to fuss (we'll delete it later)\n";
system "ssh root@`n900` passwd user";

print "setting up root\n";
keygen 'root';
print "setting up user\n";
keygen 'user';

print "deleting user password\n";
system "ssh root@`n900` passwd -d user";

system "cat *.pub > authorized_keys";

