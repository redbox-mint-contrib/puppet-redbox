#puppet-redbox using puppet : serverless
This module deploys, installs and runs redbox.

## Pre-requisites
*Tested only on CentOS 6 64bit*

*No support to run without apache proxy server.*


1.Clone/copy puppet-redbox (* you will need bitbucket access *):
```
sudo yum -y install git && git clone git@bitbucket.org:qcifltd/puppet-redbox.git /tmp/puppet-redbox && rm -Rf /tmp/puppet-redbox/.git*
```
2.setup puppet for puppet-redbox use (run as root)
```
sudo /tmp/puppet-redbox/scripts/pre-install.sh
```

3.follow puppet-hiera-redbox's README.md if installing bitbucket module puppet-hiera-redbox

## Install
```
sudo puppet apply -e "class {'puppet-redbox':}"
```

## Manual configuration needed for:
* aaf rapid setup in home/system-config.json
* export apiKey in home/system-config.json

##TODO:
* set up using r10k/heat
* improve way redbox rpm build, yum and puppet integrate
* tidy up use of redbox-system to name relevant files the redbox package name, not just 'redbox'.

## ssl-config: We use hiera-gpg and a private repo to hold this data.
Our hiera config uses hashes, which in yaml looks like:
```
ssl_config:
  cert:
  	file:
    content: |
    
  key:
  	file:
    content: |
    
  chain:
  	file:
    content: |
```
License
-------
See file, LICENCE

Contact
-------


Support
-------

Please log tickets and issues at our [Projects site](http://projects.example.com)
