#!/bin/bash
echo -e "/\"admin\": false\ns/false/true\nw\nq\n" | EDITOR=ed knife client edit `hostname -f` -c .chef/knife.rb -k /etc/chef-server/admin.pem -u admin
