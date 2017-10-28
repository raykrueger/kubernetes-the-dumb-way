#!/usr/bin/env bash

ETCDCTL_API=3 etcdctl --key=worker-1-key.pem --cert=worker-1.pem --cacert=ca.pem --endpoints https://192.168.99.100:2379 member list
