#!/usr/bin/env bash

for i in {0..2}; do
  for instance in controller-0 controller-1 controller-2 worker-0 worker-1 worker-2; do
    target="worker-${i}"

    # Do not override the route to 'self', that breaks everything
    if [ "${instance}" != "${target}" ] ; then
      docker-machine ssh ${instance} "sudo ip route add 10.200.${i}.0/24 via $(docker-machine ip worker-${i}) dev eth1 proto static"
    fi
  done
done
