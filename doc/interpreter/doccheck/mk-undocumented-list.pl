#!/usr/bin/perl -w

########################################################################
##
## Copyright (C) 2010-2024 The Octave Project Developers
##
## See the file COPYRIGHT.md in the top-level directory of this
## distribution or <https://octave.org/copyright/>.
##
## This file is part of Octave.
##
## Octave is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <https://www.gnu.org/licenses/>.
##
########################################################################

################################################################################
# File: mk-undocumented-list.pl
# Purpose: Create a list of functions present in Octave, but without a
#          corresponding DOCSTRING entry in one of the *.txi files
# Usage: make doc/interpreter/undocumented_list
# Documentation: see README in doccheck directory
################################################################################
# Get a list from Octave of all visible functions
@octave_output = <<`_END_OCT_SCRIPT_`;
../../run-octave --norc --quiet --no-history --eval '\
  funclist = vertcat (__list_functions__ , __builtins__); \
  funclist = funclist(! strncmp (funclist, \"meta.\", 5)) \
  disp ("#!-separator-!#") \
  where = cellfun (\@which, funclist, \"UniformOutput\", 0)'
_END_OCT_SCRIPT_

unless (@octave_output) { die "Unable to invoke 'run-octave'.  Exiting\n" }

################################################################################
# Winnow list of functions that require a DOCSTRING

# First, divide output in to list of functions and list of locations
$idx = 0;
while (($_ = $octave_output[$idx++]) !~ /^#!-separator-!#$/)
{
  push(@all_functions, $1) if (/] = (\w+)$/);
}
while ($_ = $octave_output[$idx++])
{
  push(@where, $1) if (/] = (.+)$/);
}

# Sanity check that Octave script worked
if ($#all_functions != $#where)
{
  die "Unequal number of functions and locations.  Parsing failed\n";
}

# Second, remove functions based on directory location
# deprecated directory, legacy directory, doc/interpreter directory,
# test/ directory
FUNC: foreach $idx (0 .. $#where)
{
  next FUNC if ($where[$idx] =~ /deprecated/i);
  next FUNC if ($where[$idx] =~ /legacy/i);
  next FUNC if ($where[$idx] =~ /interpreter/i);
  next FUNC if ($where[$idx] =~ m#test/#i);

  push (@functions, $all_functions[$idx]);
}

# Third, remove functions based on naming patterns
# Remove internal functions from the list of features requiring a DOCSTRING
@functions = grep (! /^__/, @functions);

# Fourth, remove exceptions based on name that do not require documentation
# Load list of function exceptions not requiring a DOCSTRING
# Exception data is stored at the bottom of this script
foreach $_ (<DATA>)
{ chomp, $exceptions{$_}=1; }

# Remove exception data from the list
@functions = grep (! $exceptions{$_}, @functions);

################################################################################
# Get a list of all documented functions
foreach $txi_file (glob("*.txi"))
{
  open(TXI_FILE, $txi_file) or die "Unable to open $txi_file for reading\n";
  while (<TXI_FILE>)
  {
    $docstrings{$1} = 1 if (/\@DOCSTRING\((\w+)\)/);
  }
}

################################################################################
# Find features which have not been documented in the txi files
@undocumented = grep (! $docstrings{$_}, @functions);

# Exit successfully if no undocumented functions
exit(0) if (! @undocumented);

$, = "\n";  # Set output record separator
print sort(@undocumented);
print "\n";
exit(1);

################################################################################
# Exception list of functions not requiring a DOCSTRING
################################################################################
# desktop : Remove when terminal widget is no longer experimental
################################################################################
__DATA__
angle
bessel
besselh
besseli
besselk
bessely
bug_report
chdir
dbnext
debug
desktop
end
exit
F_DUPFD
F_GETFD
F_GETFL
F_SETFD
F_SETFL
fact
finite
flipdim
fmod
gammaln
gui_mainfcn
home
i
ifelse
import
inf
inverse
isbool
isfinite
J
j
java2mat
lstat
metaclass
nan
nargchk
O_APPEND
O_ASYNC
O_CREAT
O_EXCL
O_NONBLOCK
O_RDONLY
O_RDWR
O_SYNC
O_TRUNC
O_WRONLY
putenv
rticks
setenv
slash
thetaticks
tolower
toupper
ylabel
ylim
ytickangle
yticklabels
yticks
zlabel
zlim
ztickangle
zticklabels
zticks
