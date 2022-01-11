{
  lib,
  stdenv,
  fetchzip,
  docbook_xml_dtd_45,
  docbook-xsl-nons,
  gpgme,
  glib,
  gnutls,
  libxslt,
  pkg-config,
  libnl,
  avahi,
  systemd
}:

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
    gpgme
    glib
    gnutls
    libxslt
    pkg-config
    libnl
  ];

  buildInputs = [ avahi systemd ];

  doCheck = false;

  patchPhase = ''
    sed -i 's@/usr/share/xml/docbook/stylesheet/nwalsh/xhtml/docbook.xsl@${docbook-xsl-nons}/share/xml/docbook-xsl-nons/xhtml/docbook.xsl@g' ./Makefile
    sed -i 's@/usr/share/xml/docbook/stylesheet/nwalsh/manpages/docbook.xsl@${docbook-xsl-nons}/share/xml/docbook-xsl-nons/manpages/docbook.xsl@g' ./Makefile
  '';

  buildPhase = ''
    # do nothing
    echo
  '';

  preInstall = ''
    mkdir -p \
      $out/var/lib/mandos \
      $out/usr/sbin \
      $out/etc/dbus-1/system.d \
      $out/etc/init.d/ \
      $out/etc/default/mandos \
      $out/usr/share/man/man8 \
      $out/usr/share/man/man5
  '';

  postInstall = ''
    # this directory isn't needed, clean up
    rm -rf $out/var
  '';

  installPhase = ''
    runHook preInstall
    set -x
    ls -R $out
    make install-server DESTDIR=$out
    set +x
    runHook postInstall
  '';

  meta = with lib; {
    description = "A system for allowing servers with encrypted root file systems to reboot unattended and/or remotely.";
    longDescription = ''
      Mandos is a system for allowing servers with encrypted root file systems to reboot unattended and/or remotely. See the manual <https://www.recompile.se/mandos#The_Manual_Pages> for more information, including an FAQ list.

      Mandos is Free Software, licensed using the GNU General Public License v3 or later.

      (The Halls of Mandos is, in the fictional world of J. R. R. Tolkien, where the spirits of dead elves would go to be judged and possibly reincarnated. Similarly, the Mandos system allows “dead” servers to request reincarnation, which can be either denied or granted by the Mandos server.)
    '';
    homepage = "https://www.recompile.se/mandos";
    downloadPage = "https://www.recompile.se/mandos";
    license = with licenses; gpl3Plus;
    maintainers = with maintainers; [ nukaduka ];
    platforms = with platforms; linux;
  };
}
