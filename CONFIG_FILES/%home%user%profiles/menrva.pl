#!/usr/bin/perl

# use undef or '' to leave the image thats already present
# use a single element for a preset image set
my @desktops = ('menrva.jpg');

#  number, desktop, x-pos, y-pos
#  e.g.: (['5551231234', 2, 656, 56])
my @contacts = (
  ['6318975047', 1, 656, 56],
);

#[desktop, rowsize, leftpos, toppos, itemWidth, itemHeight [items]]
#items are extensionless desktop filenames in /usr/share/applications/hildon
# e.g.: 'rtcom-call-ui' => /usr/share/applications/hildon/rtcom-call-ui.desktop
my @shortcutGrids = (
  [1, 1, 0, 56, 108, 108, [qw(
    rtcom-call-ui
    rtcom-messaging-ui
    browser
    xterm
  )]],
  [1, 1, 712, 240, 108, 108, [qw(klomp)]]
);


my $gcdir = '/apps/osso/hildon-desktop/applets/';
my $appdir = '/usr/share/applications/hildon-home/';

#[desktop, xpos, ypos, desktop_file, gconf_dir, desktop_dir]
# gconf_dir is the gconfkey prefix before the desktop_file
#   e.g.: /apps/osso/hildon-desktop/applets/
# desktop_dir is the filepath prefix before the desktop_file
#   e.g.: /usr/share/applications/hildon-home/
#
#the hyphen and index (e.g.: '-0') is appended to the end based
# on the order in the list
my @applets = (
  [1, 633, 344, "system_info", $gcdir, $appdir],
  [1, 633, 444, "personal-ip-address", $gcdir, $appdir],
);

#title, width, height, display-title =>
#update: click, desktop, boot, delay (index), network policy (index)
#desktop/view widget should be on, and (x,y) coords
#delay 0=disabled, 1=30s, 2=1min, 3=5min, 4=30min
#network 0=disabled, 1=when connected, 2=when disconnected
#       title        width  ht  disp    =>    updates     => desktop x y
#e.g.: ['rootfs',      '.10',  '1.3', 1 => 1, 1, 1, 1, 0, => 1, 0, 56],
my @dce_instances = (
  ['klomp_prev',       '.06',  '1.5', 1 => 1, 0, 0, 0, 0, => 1, 620, 56],
  ['klomp_next',       '.06',  '1.5', 1 => 1, 0, 0, 0, 0, => 1, 700, 56],
  ['klomp_bwd10',      '.06',  '1.5', 1 => 1, 0, 0, 0, 0, => 1, 620, 116],
  ['klomp_fwd10',      '.06',  '1.5', 1 => 1, 0, 0, 0, 0, => 1, 700, 116],
  ['klomp_bwd60',      '.06',  '1.5', 1 => 1, 0, 0, 0, 0, => 1, 620, 176],
  ['klomp_fwd60',      '.06',  '1.5', 1 => 1, 0, 0, 0, 0, => 1, 700, 176],
  ['klomp_pause',      '.06',  '1.5', 1 => 1, 0, 0, 0, 0, => 1, 620, 236],
  ['klomp_books',      '.06',  '1.5', 1 => 1, 0, 0, 0, 0, => 1, 700, 236],
);

my @config =
  ([@desktops], [@contacts], [@shortcutGrids], [@applets], [@dce_instances]);
@config;
