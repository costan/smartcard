require 'mkmf'
require 'pp'

$CFLAGS ||= ''
$LDFLAGS ||= ''

if RUBY_PLATFORM =~ /darwin/
  $LDFLAGS += ' -framework PCSC'
elsif RUBY_PLATFORM =~ /win/
  # TODO: no clue what to do here
else
  # pcsc is retarded and uses stuff like '#include <wintypes.h>'
  $CFLAGS += ' -I /usr/include/PCSC -I /usr/local/include/pcsc'
  have_library('pcsclite')
end

pcsc_headers = []
['wintypes.h', 'reader.h', 'winscard.h', 'pcsclite.h'].each do |header|
  ['', 'PCSC/', './pcsc_surrogate_'].each do |path_prefix|
    if have_header(path_prefix + header)
      pcsc_headers.push((path_prefix[0,1] == '.') ? "\"#{path_prefix + header}\"" : "<#{path_prefix + header}>")
      break
    end
  end
end

pcsc_defines = []

File.open('pcsc_include.h', 'w') do |f|
  pcsc_defines.each { |d| f.write "\#define #{d}\n" }
  pcsc_headers.each { |h| f.write "\#include #{h}\n" }
end 

create_makefile('smartcard/pcsc')