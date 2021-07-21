#!/bin/bash
############################################################################
#                                                                          #
# This file is part of the IPFire Firewall.                                #
#                                                                          #
# IPFire is free software; you can redistribute it and/or modify           #
# it under the terms of the GNU General Public License as published by     #
# the Free Software Foundation; either version 3 of the License, or        #
# (at your option) any later version.                                      #
#                                                                          #
# IPFire is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of           #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            #
# GNU General Public License for more details.                             #
#                                                                          #
# You should have received a copy of the GNU General Public License        #
# along with IPFire; if not, write to the Free Software                    #
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA #
#                                                                          #
# Copyright (C) 2020 IPFire-Team <info@ipfire.org>.                        #
#                                                                          #
############################################################################
#
. /opt/pakfire/lib/functions.sh
/usr/local/bin/backupctrl exclude >/dev/null 2>&1

core=158

# Remove old core updates from pakfire cache to save space...
for (( i=1; i<=$core; i++ )); do
	rm -f /var/cache/pakfire/core-upgrade-*-$i.ipfire
done

# Remove files
rm -vrf \
	/etc/rc.d/init.d/upnpd \
	/etc/rc.d/init.d/networking/red.down/10-miniupnpd \
	/etc/rc.d/init.d/networking/red.up/10-miniupnpd \
	/usr/lib/conntrack-tools \
	/usr/lib/libixml.so.* \
	/usr/lib/libupnp.so.* \
	/usr/lib/pppd/2.4.9/ \
	/var/ipfire/upnp \
	/lib/firmware/cxgb4/t4fw-1.24.14.0.bin \
	/lib/firmware/cxgb4/t5fw-1.24.14.0.bin \
	/lib/firmware/cxgb4/t6fw-1.24.14.0.bin \
	/lib/firmware/intel/ice/ddp/ice-1.3.4.0.pkg

# Stop services

# Remove dropped packages
for package in asterisk libsrtp motion libmicrohttpd sane fbset miniupnpd \
		sendEmail libupnp lcd4linux dpfhack; do
        if [ -e "/opt/pakfire/db/installed/meta-${package}" ]; then
		stop_service "${package}"
		for i in $(</opt/pakfire/db/rootfiles/${package}); do
			rm -rfv "/${i}"
		done
        fi
        rm -f "/opt/pakfire/db/installed/meta-${package}"
        rm -f "/opt/pakfire/db/meta/meta-${package}"
        rm -f "/opt/pakfire/db/rootfiles/${package}"
done

# Extract files
extract_files

# Fix permissions just in case they broke again
chmod -v 755 \
	/usr \
	/usr/bin \
	/usr/lib \
	/usr/sbin \
	/var \
	/var/ipfire

# update linker config
ldconfig

# Update Language cache
/usr/local/bin/update-lang-cache

# Filesytem cleanup
/usr/local/bin/filesystem-cleanup

# Apply local configuration to sshd_config
/usr/local/bin/sshctrl

# Start services
/etc/init.d/vnstat restart
/etc/init.d/rngd restart

# Restart apache
/etc/init.d/apache stop
/etc/init.d/apache start

# This update needs a reboot...
#touch /var/run/need_reboot

# Finish
/etc/init.d/fireinfo start
sendprofile

# Update grub config to display new core version
if [ -e /boot/grub/grub.cfg ]; then
	grub-mkconfig -o /boot/grub/grub.cfg
fi

sync

# Don't report the exitcode last command
exit 0
