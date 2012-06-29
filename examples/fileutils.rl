(ruby-require "fileutils")

[FileUtils mkdir "foo"]
(system "ls -ld foo")
[FileUtils chmod 0750 "foo"]
(system "ls -ld foo")
[FileUtils rmdir "foo"]
