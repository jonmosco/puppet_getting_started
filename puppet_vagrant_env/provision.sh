#!/usr/bin/env bash
#
# Set up the Master and Agent Nodes to talk with each other
# Purpose: Learning Puppet
#
# Master:
# - Edit /etc/hosts
# - Turn off iptables
# Node:
# - Edit /etc/hosts
# - Turn off iptables

# Change this
DOMAIN="example.com"

PATH=/bin:/sbin:/usr/bin:/usr/sbin
HOSTS="192.168.33.10 puppet.${DOMAIN} puppet
192.168.33.11 node.${DOMAIN} node"

SITE=`cat <<-END
node default {
  include profile::base
}
END
`

# Get out hostname
NAME=$( hostname -s )

case $NAME in
  puppet)
    echo "$HOSTS" >> /etc/hosts

    echo "Turning off Firewall and setting selinux to Permissive on our Puppet Master..."
    service iptables stop > /dev/null && chkconfig iptables off > /dev/null 2>&1
    #setenforce 0
    echo "Done"

    echo "Installing Puppet Master.."
    rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-7.noarch.rpm \
      > /dev/null 2>&1
    yum install puppet-server -y > /dev/null 2>&1
    echo "Done"
    echo "Building site manifest"
    echo "$SITE" >> /etc/puppet/manifests/site.pp
    echo "Done"

    echo "Starting Puppet Master Service"
    puppet resource service puppetmaster ensure=running enable=true > /dev/null 2>&1
    master=$?
    if [ $master -eq 0 ]; then
      echo "Done"
    fi
    ;;
  node)
    echo "$HOSTS" >> /etc/hosts

    echo "Turning off Firewall and setting selinux to Permissive on our Puppet Node..."
    service iptables stop > /dev/null 2>&1 \
      && chkconfig iptables off > /dev/null 2>&1
    #setenforce 0 > /dev/null 2>&1
    echo "Done"

    echo "Starting Puppet Agent Service"
    puppet resource service puppet ensure=running enable=true > /dev/null 2>&1
    agent=$?
    if [ $agent -eq 0 ]; then
      echo "Done"
    fi
    ;;
esac
