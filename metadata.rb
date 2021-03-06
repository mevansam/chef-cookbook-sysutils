name             'sysutils'
maintainer       'Mevan Samaratunga'
maintainer_email 'mevansam@gmail.com'
license          'All rights reserved'
description      'Installs/Configures sysutils'
long_description 'Resources for common environment configurations such as sysctl, users, groups, ssh keys, etc.'
version          '1.0.0'

depends          'modules', '>= 0.1.2'
depends          'hostsfile', '~> 2.4.5'
depends          'apt', '2.4.0'
depends          'yum', '3.2.2'
depends          'sudo', '2.6.0'
depends          'cron', '>= 1.2.0'
depends          'nfs', '>= 2.1.0'
