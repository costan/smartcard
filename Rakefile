require 'rubygems'
require 'echoe'

require 'tasks/ffi_codegen.rb' 

Echoe.new('smartcard') do |p|
  p.project = 'smartcard' # rubyforge project
  
  p.author = 'Victor Costan'
  p.email = 'victor@costan.us'
  p.summary = 'Interface with ISO 7816 smart cards.'
  p.url = 'http://www.costan.us/smartcard'
  p.dependencies = ['ffi >=0.5.3',
                    'rubyzip >=0.9.1',
                    'zerg_support >=0.1.5']
  p.development_dependencies = ['echoe >=3.2',
                                'flexmock >=0.8.6']
  
  p.need_tar_gz = !Gem.win_platform?
  p.need_zip = !Gem.win_platform?
  p.clean_pattern += ['ext/**/*.manifest', 'ext/**/*_autogen.h']
  p.rdoc_pattern =
      /^(lib|bin|tasks|ext)|^BUILD|^README|^CHANGELOG|^TODO|^LICENSE|^COPYING$/  
end

unless FFI::Platform.windows?
  task :package => :ffi_header
  task :test => :ffi_header
end

if $0 == __FILE__
  Rake.application = Rake::Application.new
  Rake.application.run
end
