#puppet-redbox using puppet : serverless
*Deprecated: This will be phased out, once all vms using it have been upgraded to newest module. Follow https://github.com/redbox-mint-contrib/puppet_redbox, which follows puppet standard for owner-module, and contains tests, as well as latest additions for supporting cloud and institutional builds.*

This module deploys, installs and runs redbox.

## Pre-requisites
*Tested only on CentOS 6 64bit*

## Installation

1. Download the installation bootstrap script.
```
wget https://raw.githubusercontent.com/redbox-mint-contrib/puppet-redbox/master/scripts/install.sh && chmod +x install.sh

```
2. Execute the script as root.
```
sudo install.sh
```
## Optional Features
1. Follow puppet-hiera-redbox's README.md if installing bitbucket module puppet-hiera-redbox

##TODO:

License
-------
See file, LICENCE
