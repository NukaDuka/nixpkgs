{
  lib,
  stdenv,
  fetchzip,
  docbook_xml_dtd_45,
  docbook-xsl-nons,
  gcc,
  libxslt,
  installShellFiles,
  avahi,
  python3,
  nixosTests
}:

let
  mandosPython = python3.withPackages (ps : with ps; [ dbus-python pygobject3 python3-gnutls urwid pydbus ]);
in

stdenv.mkDerivation rec {
  pname = "mandos";
  version = "1.8.14";

  src = fetchzip {
    url = "https://ftp.recompile.se/pub/mandos/mandos_${version}.orig.tar.gz";
    sha256 = "1nywcn9w5k1f1pndyxnrhhwqpzd8yla895x3jnbzrsfvj6wzsh1r";
  };

  nativeBuildInputs = [
    docbook_xml_dtd_45
    docbook-xsl-nons
    gcc
    libxslt
    installShellFiles
  ];

  propagatedBuildInputs = [
    avahi
    mandosPython
  ];

  outputs = [ "out" "man" ];

  doCheck = false;

  dontBuild = true;

  patchPhase = ''
    # In a nix-build environment, /usr/share is inaccessible, so use the docbook package paths directly instead.
    sed -i 's@/usr/share/xml/docbook/stylesheet/nwalsh/xhtml/docbook.xsl@${docbook-xsl-nons}/share/xml/docbook-xsl-nons/xhtml/docbook.xsl@g' ./Makefile
    sed -i 's@/usr/share/xml/docbook/stylesheet/nwalsh/manpages/docbook.xsl@${docbook-xsl-nons}/share/xml/docbook-xsl-nons/manpages/docbook.xsl@g' ./Makefile
    # Mandos uses a function called find_library from the python3 library cmake, which tries to search for the specified library throughout the filesystem.
    # Simplify the process by directly calling the correct library instead of relying on find_library.
    sed -i 's@_library = ctypes.cdll.LoadLibrary(library)@_library = ctypes.cdll.LoadLibrary("libgnutls.so")@g' ./mandos
    # Resolve a "conversion between byte and str" warning by the python3 interpreter
    sed -i 's@self.gpg = path@self.gpg = path.decode("utf-8")@g' ./mandos
    sed -i 's@if self.gpg == b"gpg" or self.gpg.endswith(b"/gpg"):@if self.gpg == "gpg" or self.gpg.endswith("/gpg"):@g' ./mandos
  '';

  installPhase = ''
    mkdir -p \
      $out/var/lib/mandos \
      $out/usr/sbin \
      $out/etc/dbus-1/system.d \
      $out/etc/init.d/ \
      $out/etc/default/mandos \
      $out/usr/share/man/man8 \
      $out/usr/share/man/man5 \

    mkdir -p $man

    make install-server DESTDIR=$out

    # this directory isn't needed, clean up
    rm -rf $out/var
    # install man pages
    installManPage $out/usr/share/man/man5/*.5.gz
    installManPage $out/usr/share/man/man8/*.8.gz
    installManPage $out/usr/share/man/man8/intro.8mandos.gz
    mv $out/usr/sbin $out/sbin
  '';

  passthru.tests = {
    inherit (nixosTests) mandos;
  };

  meta = with lib; {
    description = "A system for allowing servers with encrypted root file systems to reboot unattended and/or remotely.";
    longDescription = ''
      Mandos is a system for allowing servers with encrypted root file systems to reboot unattended and/or remotely. See the manual <https://www.recompile.se/mandos#The_Manual_Pages> for more information, including an FAQ list.
    '';
    homepage = "https://www.recompile.se/mandos";
    downloadPage = "https://www.recompile.se/mandos";
    license = with licenses; gpl3Plus;
    maintainers = with maintainers; [ nukaduka ];
    platforms = with platforms; linux;
  };
}
