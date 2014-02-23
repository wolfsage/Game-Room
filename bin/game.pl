#!/home/mhorsfall/perls/signatures/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/../blib/lib", "$Bin../blib/arch", "$Bin/../lib/";

use Game::Room::Map;

my $map = Game::Room::Map->new(room_file => "$Bin/../data/test.map");

$map->load();
$map->run();

