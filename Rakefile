require 'time'

task :default => :build

desc "Build everything"
task :build => ["rlisp", "doc/rlisp.1"]

# tavaiah-specific, fix for RubyForge release
desc "Build RLisp package (tar.gz and zip)"
task :package => :build do
  date_string = Time.new.gmtime.strftime("%Y-%m-%d-%H-%M")
  # Packing "rlisp" will be confusing
  files = FileList[*%w[
             doc/COPYING Rakefile README
             rlisp_shebang_support.c
             *.rb
             *.rl
             examples/*.rl
             tests/*.rl
            ]]

    files = files.map{|f| "rlisp/#{f}"}
    Dir.chdir("..") {
        sh "tar", "-z", "-c", "-f", "../website/packages/rlisp-#{date_string}.tar.gz", *files
        sh "zip", "-q", "../website/packages/rlisp-#{date_string}.zip", *files
    }
end

desc "Build RLisp package (deb)"
task :deb => :build do
  sh "dpkg-buildpackage -rfakeroot -us -uc"
end

# This is ugly, but beats doing it all by hand
#
# TODO: We could take topdir from ~/.rpmmacros
desc "Build RLisp package (rpm)"
task :rpm => ["doc/rlisp.1", :clean_all] do
  File.read("rlisp.rb") =~ /^RLISP_VERSION="(.*)"$/
  version = $1

  Dir.chdir("..") {
    n = "RLisp-#{version}"
    if File.exists?(n) and File.symlink?(n)
      puts "#{n} already exists, deleting"
      rm n
    end
    rpm_topdir = "/home/taw/.rpm-topdir/SOURCES"
    sh "ln -s trunk '#{n}'"
    sh "tar --exclude .svn -c '#{n}'/* | gzip >#{rpm_topdir}/'#{n}.tar.gz'"
  }
  sh "rpmbuild -ba RLisp.spec"
end

def time_cmd(cmd, cnt)
  cmd = "sh -c 'for i in #{(0...cnt).to_a.join(' ')}; do #{cmd}; done'" if cnt != 1
  cmd = "/usr/bin/time -f '%U+%S' #{cmd} 2>&1 >/dev/null"
  raw_time = `#{cmd}`.chomp
  raw_time =~ /\A(\d+\.\d*)\+(\d+\.\d*)\Z/ or raise "Cannot parse time: #{raw_time}"
  $1.to_f + $2.to_f
end

# This is pretty ugly
desc "Run benchmarks"
task :benchmark => :build do
    default_params = Hash.new([]).merge({
        "ackermann" => [6],
        "ary" => [400],
        "hello" => [],
    })
    default_cnt = Hash.new(1).merge({
        "hello" => 50,
        "sumcol" => 0,
    })

    implemented = FileList["benchmarks/*.rl"]
    implemented.each{|rlisp_impl|
        rlisp_impl =~ /\/(.*)\./ or raise "Benchmark file name `#{rlisp_impl}' not understood"
        name = $1
        ruby_impl = "benchmarks-ruby/#{name}.ruby"
        
        params = default_params[name]
        cnt    = default_cnt[name]
        
        next if cnt == 0

        ruby_time = time_cmd("ruby #{ruby_impl} #{params.join ' '}", cnt)
        rlisp_time = time_cmd("./rlisp.rb #{rlisp_impl} #{params.join ' '}", cnt)
       
        print "Benchmark #{name}:\n"
        print "Ruby: #{ruby_time}s\n"
        print "RLisp: #{rlisp_time}s (x#{sprintf "%0.1f", (rlisp_time.to_f/ruby_time)})\n\n"
    }
end

desc "Run all tests"
task :test => [:refresh, :build] do
  sh "./test_all.rb"
end

desc "Remove .rlc files"
task :refresh do
  rm_f FileList["*.rlc", "tests/*.rlc"]
end

desc "Compile #! support wrapper"
file "rlisp" => "shebang/rlisp_shebang_support.c" do
  rlisp_path = ENV["RLISP_PATH"] || File.dirname(__FILE__) + "/src/rlisp.rb"
  sh "gcc", "-DRLISP_PATH=\"#{rlisp_path}\"", "-Wall", "-W", "-O6", "shebang/rlisp_shebang_support.c", "-o", "rlisp"
end

file "doc/rlisp.1" => "doc/rlisp.dbk" do
  sh "xsltproc", "/usr/share/xml/docbook/stylesheet/nwalsh/manpages/docbook.xsl", "doc/rlisp.dbk"
end

task :deb_install => :build do
  destdir = ENV["DESTDIR"] or raise "DESTDIR needed"
  mkdir_p "#{destdir}/lib/ruby/1.8/"
  cp ["rlisp_highlighter.rb", "rlisp_indent.rb", "rlisp_grammar.rb", "rlisp_support.rb", "rlisp.rb"], "#{destdir}/usr/lib/ruby/1.8/"
  mkdir_p "#{destdir}/usr/bin/"
  cp ["rlisp"], "#{destdir}/usr/bin/"
  mkdir_p "#{destdir}/usr/lib/rlisp/"
  libs = %w[active_record macrobuilder rlunit sql stdlib]
  cp libs.map{|f| "#{f}.rl"}, "#{destdir}/usr/lib/rlisp/"
  libs.each{|l|  sh './rlisp.rb', '-e', "(require \"#{l}.rl\")" }
  cp libs.map{|f| "#{f}.rlc"}, "#{destdir}/usr/lib/rlisp/"
end

task :rpm_install => :build do
  destdir = ENV["DESTDIR"] or raise "DESTDIR needed"
  mkdir_p "#{destdir}/usr/share/doc/RLisp"
  cp ["README", "debian/copyright"], "#{destdir}/usr/share/doc/RLisp"
  
  mkdir_p "#{destdir}/usr/share/man/man1"
  sh "gzip <rlisp.1 >#{destdir}/usr/share/man/man1/rlisp.1.gz"

  mkdir_p "#{destdir}/usr/lib/ruby/vendor_ruby/1.8/"
  cp ["rlisp_highlighter.rb", "rlisp_indent.rb", "rlisp_grammar.rb", "rlisp_support.rb", "rlisp.rb"], "#{destdir}/usr/lib/ruby/vendor_ruby/1.8/"
  mkdir_p "#{destdir}/usr/bin/"
  sh "gcc '-DRLISP_PATH=\"/usr/lib/ruby/vendor_ruby/1.8/rlisp.rb\"' -Wall -W -O rlisp_shebang_support.c -o '#{destdir}/usr/bin/rlisp'"
  mkdir_p "#{destdir}/usr/lib/rlisp/"
  libs = %w[active_record macrobuilder rlunit sql stdlib]
  cp libs.map{|f| "#{f}.rl"}, "#{destdir}/usr/lib/rlisp/"
  libs.each{|l|  sh './rlisp.rb', '-e', "(require \"#{l}.rl\")" }
  cp libs.map{|f| "#{f}.rlc"}, "#{destdir}/usr/lib/rlisp/"
end

desc "Clean generated files"
task :clean do
  generated_files = FileList["*.rlc", "tests/*.rlc", "rlisp"]
  rm_f generated_files
end

desc "Clean after building Debian package"
task :deb_clean do
  sh "fakeroot debian/rules clean"
end

desc "Clean generated files (really)"
task :clean_all => [:clean, :deb_clean]

class File
  def self.update_contents(file_name)
    old_contents = File.read(file_name)
    new_contents = yield(old_contents)
    if old_contents != new_contents
      #STDERR.puts "Contents of #{file_name} updated"
      File.open(file_name, "w") {|fh| fh.print new_contents}
    else
      #STDERR.puts "Contents of #{file_name} are the same"
    end
  end
end

desc "Update version number"
task :version_update do
  File.read("rlisp.rb") =~ /^RLISP_VERSION="(.*)"$/
  cur_version = $1
  if cur_version =~ /\A0.1.\d{8}\Z/
    new_version = "0.1." + Time.now.strftime("%Y%m%d")
  else
    raise "Unrecognized version format: `#{cur_version}', expected 0.1.YYYYMMDD"
  end
  if cur_version == new_version
    puts "Version is already `#{new_version}'"
  elsif cur_version > new_version
    raise "Updating from version `#{old_version}' to version `#{new_version}' would break timespace continuum"
  else
    File.update_contents("rlisp.rb") do |cnt|
      cnt.gsub(/^RLISP_VERSION=".*"$/, %Q[RLISP_VERSION="#{new_version}"]) 
    end
  
    File.update_contents("RLisp.spec") do |cnt|
      cnt.gsub(/^Version: .*$/, "Version: #{new_version}") 
    end
    File.update_contents("debian/changelog") do |cnt|
      entry = <<EOF
rlisp (#{new_version}) unstable; urgency=low

  * Upstream update
  
 -- Tomasz Wegrzanowski <Tomasz.Wegrzanowski@gmail.com>  #{Time.now.rfc822}
   
EOF
      entry + cnt
    end
  end
end
