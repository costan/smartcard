require 'rubygems'
require 'echoe'

require './tasks/ffi_codegen.rb'

Echoe.new('smartcard') do |p|
  p.project = 'smartcard' # rubyforge project

  p.author = 'Victor Costan'
  p.email = 'victor@costan.us'
  p.summary = 'Interface with ISO 7816 smart cards.'
  p.url = 'http://www.costan.us/smartcard'
  p.dependencies = ['ffi >=1.2.0',
                    'rubyzip >=0.9.9',
                    'zip-zip >=0.3',
                    'zerg_support >=0.1.6']
  p.development_dependencies = ['echoe >=4.6.3',
                                'flexmock >=1.2.0']

  p.need_tar_gz = !Gem.win_platform?
  p.need_zip = !Gem.win_platform?
  p.clean_pattern += ['ext/**/*.manifest', 'ext/**/*_autogen.h']
  p.rdoc_pattern =
      /^(lib|bin|tasks|ext)|^BUILD|^README|^CHANGELOG|^TODO|^LICENSE|^COPYING$/
end

file 'lib/smartcard/pcsc/ffi_autogen.rb' => 'tasks/ffi_codegen.rb' do
  Smartcard::Tasks.generate_ffi_header
end

unless FFI::Platform.windows?
  task :package => 'lib/smartcard/pcsc/ffi_autogen.rb'
  task :test => 'lib/smartcard/pcsc/ffi_autogen.rb'
end

if $0 == __FILE__
  Rake.application = Rake::Application.new
  Rake.application.run
end
