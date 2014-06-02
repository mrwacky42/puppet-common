# Create a whole file (whole {}) from fragments (frag {})
# Copyright (C) 2012-2013+ James Shubin
# Written by James Shubin <james@shubin.ca>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# thanks to #puppet@freenode.net for some good implementation advice

define whole(
	$dir,				# the directory to store the fragment
	$owner = root,			# the file {} defaults were used here
	$group = root,
	$mode = '644',
	$backup = undef,		# the default value is actually: puppet
	$pattern = '',			# /usr/bin/find -name <pattern> is used
	$frag = false,			# set true to also act like a frag obj!
	$ensure = present		# TODO: does absent even work properly?
) {
	$d = sprintf("%s/", regsubst($dir, '\/$', ''))	# ensure trailing slash
	$safe_d = shellquote($d)
	$safe_p = shellquote($pattern)
	$command = $pattern ? {
		'' => "/usr/bin/find ${safe_d} -maxdepth 1 -type f -print0 | /bin/sort -z | /usr/bin/xargs -0 /bin/cat",
		default => "/usr/bin/find ${safe_d} -maxdepth 1 -name ${safe_p} -type f -print0 | /bin/sort -z | /usr/bin/xargs -0 /bin/cat",
	}

	# this is the parent (basename) dir of $name which is special if i frag
	$frag_d = sprintf("%s/", regsubst($name, '((\/[\w.-]+)*)(\/)([\w.-]+)', '\1'))

	# the file (used to set perms and as a placeholder so it's not deleted)
	file { "${name}":
		ensure => $ensure,
		owner => $owner,
		group => $group,
		mode => $mode,
		backup => $backup,
		checksum => 'md5',
		before => $frag ? {		# used when this is also a frag
			true => Exec["${frag_d}"],
			default => undef,
		}
	}

	# ensure directory exists and is managed
	file { "${d}":
		ensure => directory,		# make sure this is a directory
		recurse => true,		# recursively manage directory
		purge => true,			# purge all unmanaged files
		force => true,			# also purge subdirs and links
		before => Exec["${d}"],
	}

	# actually make the file from fragments with this command
	# use >| to force target file clobbering (ignore a: "set -o noclobber")
	exec { "${d}":
		command => "${command} >| ${name}",
		# NOTE: if we don't use 'bash -c' this spurriously sends notify
		# actually check that the file matches what it really should be
		unless => "/bin/bash -c '/usr/bin/diff -q <(/bin/cat ${name}) <(${command})'",
		logoutput => on_failure,
		# if we're a frag, make sure that we build ourself out before
		# the parent `whole` object which uses us, builds itself out!
		before => $frag ? {
			true => Exec["${frag_d}"],
			default => undef,
		},
		# if we're a frag, then it's important to wait for the parent
		# frag collection directory to get created before i make this
		require => $frag ? {
			true => File["${frag_d}"],
			default => undef,
		},
	}
}

# vim: ts=8
