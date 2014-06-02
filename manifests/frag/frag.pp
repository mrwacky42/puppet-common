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

# frag supports both $source and $content. if $source is not empty, it is used,
# otherwise content is used. frag should behave like a first class file object.
define frag(				# dir to store frag, is path in namevar
	$owner = root,			# the file {} defaults were chosen here
	$group = root,
	$mode = '644',
	$backup = undef,		# the default value is actually: puppet
	$ensure = present,
	$content = '',
	$source = ''
	# TODO: add more file object features if someone needs them or if bored
) {
	# finds the file name in a complete path; eg: /tmp/dir/file => file
	#$x = regsubst($name, '(\/[\w.]+)*(\/)([\w.]+)', '\3')
	# finds the basepath in a complete path; eg: /tmp/dir/file => /tmp/dir/
	$d = sprintf("%s/", regsubst($name, '((\/[\w.-]+)*)(\/)([\w.-]+)', '\1'))

	# the file fragment
	file { "${name}":
		ensure => $ensure,
		owner => $owner,
		group => $group,
		mode => $mode,
		backup => $backup,
		content => $source ? {
			'' => $content,
			default => undef,
		},
		source => $source ? {
			'' => undef,
			default => $source,
		},
		before => Exec["${d}"],
		require => File["${d}"],
	}
}

# vim: ts=8
