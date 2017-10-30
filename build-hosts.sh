#!/usr/bin/env bash

create_hosts() {
  basename=$1
  for n in {0..2} ; do
    name=${basename}-${n}
    printf "\n---Create ${name}\n"
    docker-machine create -d virtualbox --virtualbox-memory "2048" ${name}
    [ $? -ne 0 ] && exit $?

    # TODO HACK This is a hack to get tce-load to install iptables/netfilter in
    # boot2docker. The boot2docker devs got cute and changed the uname.
    docker-machine ssh ${name} "sudo sed -i 's/KERNELVER=\$(uname -r)/KERNELVER=4.2.7-tinycore64/' /usr/bin/tce-load"
  done
}

create_hosts controller
create_hosts worker
