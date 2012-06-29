(ruby-require "digest/md5")
(ruby-require "digest/sha1")

(defun md5 (val) [Digest::MD5 hexdigest val])
(defun sha1 (val) [Digest::SHA1 hexdigest val])

(let val "Foo")
(print "MD5 of #{val} is #{(md5 val)}")
(print "SHA1 of #{val} is #{(sha1 val)}")
