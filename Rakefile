require 'rubygems'
gem 'echoe'
require 'echoe'

Echoe.new('smartcard') do |p|
  p.project = 'smartcard' # rubyforge project
  
  p.author = 'Victor Costan'
  p.email = 'victor@costan.us'
  p.summary = 'Interface with ISO 7816 smart cards.'
  p.url = 'http://www.costan.us/smartcard'
  
  p.need_tar_gz = false
  p.clean_pattern += ['ext/**/*.manifest', 'ext/**/*_autogen.h']
  p.rdoc_pattern = /^(lib|bin|tasks|ext)|^BUILD|^README|^CHANGELOG|^TODO|^LICENSE|^COPYING$/
  
  p.eval = proc do |p|
    if Platform.windows?
      p.files += ['lib/smartcard/pcsc.so']
      p.platform = Gem::Platform::CURRENT

      # take out the extension info from the gemspec
      task :postcompile_hacks => [:compile] do
        p.extensions.clear
      end

      task :package => [ :clean, :compile, :postcompile_hacks ]
    end
  end
end

if $0 == __FILE__
  Rake.application = Rake::Application.new
  Rake.application.run
end
