#!/usr/bin/perl
use strict;
use warnings;

if(ask 'install gcc-4.2 & g++-4.2 from SDK repo {disabled after}, and add links?'){
  system "ssh root@`n900` '" .
    "cd /etc/apt/sources.list.d; " .
    "mv sdk.list.disabled sdk.list; " .
    "apt-get update; " .
    "apt-get install gcc-4.2 g++-4.2; " .
    "mv sdk.list sdk.list.disabled; " .
    "apt-get update; " .
    "ln -s /usr/bin/gcc-4.2 /usr/bin/gcc; " .
    "ln -s /usr/bin/gcc-4.2 /usr/bin/cc; " .
    "ln -s /usr/bin/g++-4.2 /usr/bin/g++; " .
    "'";
}
