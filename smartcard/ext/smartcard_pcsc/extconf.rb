require 'mkmf'
require 'pp'

$LDFLAGS ||= ''

pcsc_headers = []
['wintypes.h', 'reader.h', 'winscard.h'].each do |header|
  ['', 'PCSC/', './pcsc_surrogate_'].each do |path_prefix|
    if have_header(path_prefix + header)
      pcsc_headers.push((path_prefix[0,1] == '.') ? "\"#{path_prefix + header}\"" : "<#{path_prefix + header}>")
      break
    end
  end
end

pcsc_defines = []
if RUBY_PLATFORM =~ /darwin/
  $LDFLAGS += ' -framework PCSC'
elsif RUBY_PLATFORM =~ /win/
  # TODO: no clue what to do here
else
  have_library('pcsclite')
end

File.open('pcsc_include.h', 'w') do |f|
  pcsc_defines.each { |d| f.write "\#define #{d}\n" }
  pcsc_headers.each { |h| f.write "\#include #{h}\n" }
end 

create_makefile('smartcard_pcsc')