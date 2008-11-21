= Builds are hard
+smartcard+ needs to talk to hardware (card readers), so it's bound to use a Ruby extension.
This means C, and platform-specific building nightmares. Read below for details.

= The build system
+smartcard+ uses {echoe}[http://blog.evanweaver.com/files/doc/fauna/echoe/] for builds. This
automates most of the building and packaging work, and can even push the gem to rubyforge,
with a bit of luck. Most used commands:
	rake manifest # builds the manifest (do this after checking out)
	rake package # builds the gem for your platform
	rake mswin package # cross-builds the gem for Windows
	rake test # builds the gem and runs the tests
	rake docs # runs Rdoc to produce the docs

On the other hand, you have to <tt>gem install echoe</tt> to be able to build anything.

= Platform-specific information

== OSX

You need to install the Developer Tools to get gcc.

Leopard includes a working PC/SC provider, as well as a good driver for CCID readers.
Tiger's PC/SC implementation is broken and incomplete, so the Ruby extension code in +smartcard+
has a few hacks to work around that (look for the <tt>RB_SMARTCARD_OSX_TIGER_HACK</tt> define.
The following commands are broken / don't work:
* Smartcard::PCSC::Context#is_valid (always returs +true+)
* Smartcard::PCSC::Card#get_attribute (throws exception because it's not implemented)
* Smartcard::PCSC::Card#set_attribute (throws exception because it's not implemented)
* Smartcard::PCSC::Card#control (Tiger's API is broken, so the call will probably not work)

The developer team doesn't support or test against ports of +gcc+ or +pcsclite+,
but we success notifications are welcome.

== Windows

A lot of effort has been spent to make Windows builds as easy as possible.
+smartcard+ is currently built using a full edition of
{Visual Studio 2005}[http://msdn.microsoft.com/vstudio/], but all sources
indicate that {Visual C++ Express 2005}[http://www.microsoft.com/express/download/] works,
as long as you also install a Windows SDK (you're on your own for that). Visual Studio 2008
might work, but it hasn't been tested yet.

A summary of the hacks that have been done to get Windows builds working:
* removing the extension files from the gemspec at the "right time" so that +echoe+ compiles the extension, and the gem doesn't require re-compilation (see the +Rakefile+)
* adding the compiled extension to the file list in the gemspec
* adding code to <tt>extconf.rb</tt> to patch the +Makefile+ so a manifest is embedded in the extension dll (and ruby doesn't crash if it uses a different version of the C runtime)

== Linux

+smartcard+ is developed (and tested) against the
{MUSCLE project}[http://www.linuxnet.com/software.html]. If you go this route, you need to
get at least the {pcsclite library}[http://pcsclite.alioth.debian.org/] and a driver.
+smartcard+ developers use the {CCID driver}[http://pcsclite.alioth.debian.org/], which
works on most (new) readers.

=== Ubuntu

Installing the following packages (and their dependencies) gets you going on Ubuntu (tested on 7.10):
* buildessentials
* libccid
* libpcsclite
* libpcsclite-dev
* pcscd
* pcsc-tools
