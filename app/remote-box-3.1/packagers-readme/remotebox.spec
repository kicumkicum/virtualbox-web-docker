# EXAMPLE SPEC FILE FOR BUILDING A FEDORA BASED RPM OF REMOTEBOX
# Modification may be required for other RPM based distros.
#
# You are free to modify and distribute this SPEC as you see fit.

%global pkgname  RemoteBox

# We need to filter some dependencies that the RPM auto-dependency
# gatherer picks up, as they are private to RemoteBox and reside
# within the RPM.
%global __requires_exclude ^perl\\(.*\\.pl\\)|^perl\\(vboxService\\)

# We don't want to be a provider of vboxService as it's
# private to RemoteBox, so filter it.
%global __provides_exclude ^perl\\(vboxService\\)


Name:           remotebox
Version:        3.1
Release:        1%{?dist}
Summary:        A VirtualBox client with remote management
License:        GPLv2+
URL:            http://knobgoblin.org.uk
Source0:        http://knobgoblin.org.uk/downloads/%{pkgname}-%{version}.tar.bz2
BuildArch:      noarch
BuildRequires:  desktop-file-utils
Requires:       perl-Gtk3
Requires:       freerdp

%description
VirtualBox is traditionally considered to be a virtualization solution aimed
at the desktop as opposed to other solutions such as KVM, Xen and VMWare ESX
which are considered more server orientated solutions. While it is certainly
possible to install VirtualBox on a server, it offers few remote management
features beyond using the vboxmanage command line. RemoteBox aims to fill
this gap by providing a graphical VirtualBox client which is able to
communicate with and manage a VirtualBox server installation.


%prep
%setup -q -n %{pkgname}-%{version}
# Set the locations of Remotebox's files
sed -i 's|\$Bin/share/remotebox|%{_datadir}/%{name}|g' remotebox


%build
# Create a desktop file
cat >%{name}.desktop <<EOF
[Desktop Entry]
Name=RemoteBox
Comment=Remote VirtualBox client
Exec=remotebox
Icon=remotebox
Terminal=false
Type=Application
StartupNotify=false
Categories=Emulator;System;
EOF


%install
mkdir -p -m0755 %{buildroot}%{_datadir}/{%{name},pixmaps,applications,appdata}
mkdir -p -m0755 %{buildroot}%{_bindir}
install -p -m0755 %{name} %{buildroot}%{_bindir}
cp -a share/%{name}/* %{buildroot}%{_datadir}/%{name}

# Install the .desktop file
desktop-file-install --dir=%{buildroot}%{_datadir}/applications \
                     %{name}.desktop

# Install an icon for the desktop file
install -p -m0644 share/%{name}/icons/%{name}.png %{buildroot}%{_datadir}/pixmaps

# Install the appdata file
install -p -m0644 packagers-readme/%{name}.appdata.xml %{buildroot}%{_datadir}/appdata


%check
desktop-file-validate %{buildroot}/%{_datadir}/applications/%{name}.desktop


%files
%defattr(-,root,root,-)
%doc docs/changelog.txt docs/%{name}.pdf docs/COPYING
%{_datadir}/applications/%{name}.desktop
%{_datadir}/pixmaps/%{name}.png
%{_datadir}/appdata
%{_datadir}/%{name}
%{_bindir}/%{name}


%changelog
* Sat Nov 13 2021 Ian Chapman <packages[AT]amiga-hardware.com> - 3.0-1
- Example SPEC file for RemoteBox
