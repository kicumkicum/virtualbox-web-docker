Introduction
------------
This simple readme is intended to provide a few pointers to anybody who wishes
to package RemoteBox for their operating system. In other words anybody who
wants to create an RPM, DEB, PKG or other type of package.

Example SPEC File
-----------------
There is an example SPEC file located in this directory which can be used to
build an RPM of RemoteBox on Fedora. It may require modification to build
correctly on other RPM based distributions. The SPEC file generates its own
.desktop file, but a separate example .desktop file is also included.

An .appdata.xml file is also included for use with distributions which support
it. These are generally installed in /usr/share/appdata. You should verify that
the name of the .desktop file that the .appdata.xml file references, matches
correctly the name of the .desktop file that your package installs.

Dependencies
------------
RemoteBox has the following software dependencies:

* Perl (v5.24 or newer is recommended. Earlier versions may work)
* GTK 3 (v3.22 minimum)
* SOAP::Lite perl module
* libwww-perl perl modules (usually depended on by the SOAP::Lite module)
* perl-Gtk3 perl modules
* FreeRDP (default) or rdesktop (or TigerVNC for systems only support VNC servers)
    - RemoteBox will function (except remote display) without an RDP/VNC client but
      can be easily patched to use an alernative RDP/VNC client as the default. The
      user can of course configure their client of choice. On Windows the default
      RDP client is the mtstc as supplied with Windows. The default VNC client is TigerVNC

Depending on your packaging manager, you do not necessarily need to make all
these explicit dependencies in your package. For example, most packaging
systems would ensure Perl was installed if a package required perl-Gtk3.

Patching RemoteBox
------------------
1. RemoteBox is designed to run directly from the unpacked tarball and doesn't
   require installation but is also intended to be easily packaged for a
   system-wide installation. You may need to patch the following line in
   the main executable file called 'remotebox'. Note '$Bin' is a special
   variable which expands to the directory remotebox ran from.

       our $sharedir = "$Bin/share/remotebox";

   The $sharedir defines the location of all of RemoteBox's dependent files and
   should be set to the location where they will be installed. Under Fedora for
   example, this might be defined as:

    our $sharedir = '/usr/share/remotebox';
