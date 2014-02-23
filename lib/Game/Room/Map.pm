package Game::Room::Map;

# Initial playing around

use strict;
use warnings;

#use feature qw(signatures);
#no warnings 'experimental::signatures';

use mop;
use Carp ();
use Term::ReadKey;

class Game::Room::Map {
	has $!room_file = "";
	has $!grid;            # $!grid[y][x] - the map
	has $!cx;              # Current player x position
	has $!cy;              # Current player y position

	has $!message = "";    # Anything we need to tell player

	has $!visible = {};    # List of things the user has seen
	has $!lradius = 2;     # Light radius

	has $!character = 's'; # The player

	method load {
		if (! -e $!room_file) {
			Carp::croak(sprintf("Failed to load map file (%s): %s\n", $!room_file, $!));
		}

		my @grid;

		open(my $f, '<', $!room_file) or Carp::croak(sprintf("Failed to load map file (%s): %s\n", $!room_file, $!));
		my @data = <$f>;
		close($f);

		for my $l (@data) {
			my @row = split(//, $l);
			push @grid, [@row];
		}

		my $start;

		my $y = 0;

		# Find character starting position
		for my $row (@grid) {
			my $x = 0;

			for my $col (@$row) {
				if ($col eq $!character) {
					$!cx = $x;
					$!cy = $y;

					last;
				}

				$x++;
			}

			$y++;
		}

		if (! defined($!cx)) {
			Carp::croak(sprintf("Failed to load map %s: No start position marker found", $!room_file));
		}

		$!grid = \@grid;
	}

	method draw {
		system('clear');

		my $y = 0;
		for my $row (@{$!grid}) {
			my $x = 0;

			# Only draw what can be seen
			for my $col (@$row) {
				if ($!visible->{$x}{$y}) {
					# Already seen by user
					print $col;
				} elsif ($col eq "\n") {
					print $col;
				} elsif ($col ne ' ' && $col ne $!character) {
					# Within user's light radius?
					if (abs($!cy - $y) <= $!lradius && abs($!cx - $x) <= $!lradius) {
						print $col; $!visible->{$x}{$y} = 1;
					} else {
						print " ";
					}
				} else {
					# Character or empty space
					print $col;
				}

				$x++;
			}

			$y++;
		}

		print "\n" . $!message . "\n";
	}

	method get_move {
		my $key;

		ReadMode 4; # Turn off controls keys
		my %okay = map { $_ => 1 } qw(j h k l q);

		# Heavily loops on CPU... need better than ReadKey
		while (1) {
			$key = ReadKey(-1);
			if (defined $key && $okay{$key}) {
				last;
			} elsif ($key) {
				$!message = "Unknown key! Try [hjkl], [q] to quit";
				$self->draw();
			}
		}

		ReadMode 0;

		if ($key eq 'q') {
			print "Good bye!\n";
			exit;
		}

		my ($x, $y) = ($!cx, $!cy);

		if ($key eq 'h') { $x-- } # left
		if ($key eq 'l') { $x++ } # right
		if ($key eq 'j') { $y++ } # down
		if ($key eq 'k') { $y-- } # up

		$self->attempt_move($x, $y);
	}

	method attempt_move ($newx, $newy) {
		my $next = $!grid->[$newy][$newx];

		# "Collision Detection". Can only move to exit or empty space
		if ($next eq 'e' || $next eq ' ') {
			$!grid->[$!cy][$!cx] = ' ';
			($!cy, $!cx) = ($newy, $newx);
			$!grid->[$!cy][$!cx] = $!character;

			if ($next eq 'e') {
				$!message = "You win!\n";
				$self->draw();
				exit;
			} else {
				$!message = "";
			}
		} else {
			$!message = "Bonk!\n";
		}
	}

	method run {
		while (1) {
			$self->draw();
			$self->get_move();
		}
	}
}

1;
