# dns-here
Run a temporary DNS server that resolves a given hostname to the current IP

Useful if you want to test a website you are working on locally on iOS or Android, where you cannot edit the hosts file.

It does its thing inside a docker container so nothing has to be installed.

Works nicely for my Debian desktop. But before running it you should read the script and how it handles systemd-resolved and /etc/resolv.conf. This might not be the way to go on other systems and might wreck havoc if your system is set up differently then mine.

Run it like this:

./dns-here.sh example.com

Then set the local IP on as the DNS server on the device you want to test the website on.

Now that device will find your local development machine under the given hostname.

License: GNU General Public License, version 2
