Name: RLisp
Version: 0.1.20070617
Release: 1
License: X11/MIT
Group: Development/Languages/Ruby
URL: http://rubyforge.org/projects/lisp/
Summary: Lisp naturally integrated with Ruby
BuildRoot: %{_tmppath}/%{name}-%{version}-build
Source0: %{name}-%{version}.tar.gz

%define mod_name RLisp
%description
 RLisp is a Lisp with full access to Ruby virtual machine,
 or from other point of view Ruby with Lisp macros.

%prep
%setup -q

%build
# Nothing to do

%install
rake DESTDIR=%{buildroot} rpm_install

%clean
%{__rm} -rf %{buildroot}

%files
%dir %{_libdir}/rlisp
%{_libdir}/rlisp/stdlib.rl
%{_libdir}/rlisp/rlunit.rl
%{_libdir}/rlisp/sql.rl
%{_libdir}/rlisp/rlunit.rlc
%{_libdir}/rlisp/sql.rlc
%{_libdir}/rlisp/stdlib.rlc
%{_libdir}/rlisp/macrobuilder.rl
%{_libdir}/rlisp/macrobuilder.rlc
%{_libdir}/rlisp/active_record.rl
%{_libdir}/rlisp/active_record.rlc
%{_libdir}/ruby/vendor_ruby/1.8/rlisp.rb
%{_libdir}/ruby/vendor_ruby/1.8/rlisp_highlighter.rb
%{_libdir}/ruby/vendor_ruby/1.8/rlisp_indent.rb
%{_libdir}/ruby/vendor_ruby/1.8/rlisp_support.rb
%{_libdir}/ruby/vendor_ruby/1.8/rlisp_grammar.rb
%dir %{_docdir}/%{name}
%doc %{_docdir}/%{name}/README
%doc %{_docdir}/%{name}/copyright
/usr/share/man/man1/rlisp.1.gz
/usr/bin/rlisp

