#!/usr/bin/perl
use strict;
use warnings;

sub prompt($){
  my $msg = shift;
  print "\n\n$msg [y/N] ";
  my $response = <STDIN>;
  chomp $response;
  if(lc $response eq 'y'){
    return 1;
  }else{
    print "skipped\n";
    return 0;
  }
}

if(prompt 'Are you absolutely sure you know what youre doing?'){
  my $latest = '/media/mmc1/Backup/Latest';
  my $link = `ssh root@\`n900\` ls -l $latest`;
  if($link =~ /-> \/media\/mmc1\/Backup\/([0-9_-]+)\n$/){
    print "!!! Latest backup date is: $1\n";
  }else{
    print "!!! Unknown backup date; is microSD mounted?\n";
  }

  print "This will DESTROY all your current contacts.\n";
  print "To continue, type 'destroy contacts' without the quotes\n";
  my $response = <STDIN>;
  chomp $response;
  if(lc $response eq 'destroy contacts'){
    my $file = "$latest/osso-addressbook-backup";
    system "ssh root@`n900` 'echo " .
      "\"osso-addressbook-backup -i $file\"" .
      " | su - user'";
  }else{
    print "skipped\n";
  }
}

