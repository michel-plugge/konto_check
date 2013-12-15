# Copyright (c) 2010 -2011 Peter Horn <peter.horn@provideal.net>,
#                          Jan Schwenzien <jan@schwenzien.org>
#                          Michael Plugge <m.plugge@hs-mannheim.de>
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'konto_check_raw'

if have_library("z", "uncompress")
  # The destination
  dir_config(extension_name)

  # Do the work
  create_makefile(extension_name)
  # esoteric makefile line for private development stuff - comment it out for normal build
#  File.open("Makefile","a"){|mf| mf.puts("\nkonto_check.c: konto_check.lxx konto_check-cfg.lxx\n	lx2l -x konto_check.lxx\nkonto_check_raw_ruby.c: konto_check_raw_ruby.lxx konto_check-cfg.lxx\n	lx2l -x konto_check_raw_ruby.lxx\nextconf.rb: extconf.lx konto_check-cfg.lxx\n	lx2l extconf.lx\nMakefile: extconf.rb\n	ruby extconf.rb\ninst: install\n	cp -u konto_check_raw.so /home/michel/.rvm/gems/ruby-1.9.2-p180/gems/konto_check-0.2.2/ext/konto_check_raw/\n	cp -u konto_check_raw.so /home/michel/.rvm/gems/ruby-1.9.2-p180/gems/konto_check-0.2.2/lib/\nt: inst\n	irb <0_test") } 
#  system("perl -pi -e 's/-O3/-O0/g' Makefile")
else
  puts("Sadly, I can't find zlib. But I need it to compile. :(")
end

