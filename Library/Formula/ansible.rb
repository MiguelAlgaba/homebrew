require 'formula'

class PyYAML < Formula
  url 'https://pypi.python.org/packages/source/P/PyYAML/PyYAML-3.10.tar.gz'
  sha1 '476dcfbcc6f4ebf3c06186229e8e2bd7d7b20e73'
end

class Paramiko < Formula
  url 'https://pypi.python.org/packages/source/p/paramiko/paramiko-1.11.0.tar.gz'
  sha1 'fd925569b9f0b1bd32ce6575235d152616e64e46'
end

class MarkupSafe < Formula
  url 'https://pypi.python.org/packages/source/M/MarkupSafe/MarkupSafe-0.18.tar.gz'
  sha1 '9fe11891773f922a8b92e83c8f48edeb2f68631e'
end

class Jinja2 < Formula
  url 'https://pypi.python.org/packages/source/J/Jinja2/Jinja2-2.7.1.tar.gz'
  sha1 'a9b24d887f2be772921b3ee30a0b9d435cffadda'
end

class PyCrypto < Formula
  url 'https://pypi.python.org/packages/source/p/pycrypto/pycrypto-2.6.tar.gz'
  sha1 'c17e41a80b3fbf2ee4e8f2d8bb9e28c5d08bbb84'
end

class PythonKeyczar < Formula
  url 'https://pypi.python.org/packages/source/p/python-keyczar/python-keyczar-0.71b.tar.gz'
  sha1 '20c7c5d54c0ce79262092b4cc691aa309fb277fa'
end

class Ansible < Formula
  homepage 'http://www.ansibleworks.com/'
  url 'https://github.com/ansible/ansible/archive/v1.3.3.tar.gz'
  sha1 'e3e0b936c8bf0d892aec5730dd3dd5aa0a0419d1'

  head 'https://github.com/ansible/ansible.git', :branch => :devel

  depends_on :python
  depends_on 'libyaml'

  option 'with-accelerate', "Enable accelerated mode"

  # TODO: Move this into Library/Homebrew somewhere (see also mitmproxy.rb).
  def wrap bin_file, pythonpath
    bin_file = Pathname.new bin_file
    libexec_bin = Pathname.new libexec/'bin'
    libexec_bin.mkpath
    mv bin_file, libexec_bin
    bin_file.write <<-EOS.undent
      #!/bin/sh
      PYTHONPATH="#{pythonpath}:$PYTHONPATH" "#{libexec_bin}/#{bin_file.basename}" "$@"
    EOS
  end

  def install
    install_args = [ "setup.py", "install", "--prefix=#{libexec}" ]

    python do
      PyCrypto.new.brew { system python, *install_args }
      PyYAML.new.brew { system python, *install_args }
      Paramiko.new.brew { system python, *install_args }
      MarkupSafe.new.brew { system python, *install_args }
      Jinja2.new.brew { system python, *install_args }
      if build.with? 'accelerate'
        PythonKeyczar.new.brew { system python, *install_args }
      end

      inreplace 'lib/ansible/constants.py' do |s|
        s.gsub! '/usr/share/ansible', share+'ansible'
        s.gsub! '/etc/ansible', etc+'ansible'
      end

      # The "main" ansible module is installed in the default location and
      # in order for it to be usable, we add the private_site_packages
      # to the __init__.py of ansible so the deps (PyYAML etc) are found.
      inreplace 'lib/ansible/__init__.py',
                "__author__ = 'Michael DeHaan'",
                "__author__ = 'Michael DeHaan'; import site; site.addsitedir('#{python.private_site_packages}')"

      system python, "setup.py", "install", "--prefix=#{prefix}"
    end

    man1.install Dir['docs/man/man1/*.1']

    Dir["#{bin}/*"].each do |bin_file|
      wrap bin_file, python.site_packages
    end
  end

  def test
    system "#{bin}/ansible", "--version"
  end
end
