require 'mkmf'

$LDFLAGS ||= ''

pcsc_headers = []
pcsc_defines = []
if RUBY_PLATFORM =~ /darwin/
  pcsc_headers += ['<PCSC/winscard.h>']
  pcsc_headers += ['"pcsc_surrogate_wintypes.h"', '"pcsc_surrogate_reader.h"']
  $LDFLAGS += ' -framework PCSC'
elsif RUBY_PLATFORM =~ /win/
  pcsc_headers += ['<winscard.h>']
else
  pcsc_headers += ['<winscard.h>']
end

File.open('pcsc_include.h', 'w') do |f|
  pcsc_defines.each { |d| f.write "\#define #{d}\n" }
  pcsc_headers.each { |h| f.write "\#include #{h}\n" }
end 

create_makefile('smartcard_pcsc')