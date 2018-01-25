# Kubernetes the Dumb Way

The amazing [Kelsey Hightower](https://github.com/kelseyhightower) put together
a great guide called "[Kubernetes the Hard
Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)". If you want
to understand the inner workings of how a Kubernetes cluster gets built, what
the components are, and how they're used, I highly recommend reading through
and following Kelsey's guide.

What I have done here is an abomination and a travesty. I warn you now traveller,
turn back. What follows is an exercise in brutality and masochism.

## Target Audience

Me. I wrote the code for me. I wrote the README for you.

## The Steps

1. [Install Docker for Mac](https://store.docker.com/editions/community/docker-ce-desktop-mac)
1. [Install VirtualBox](https://www.virtualbox.org/)
1. [Install cfssl and cfssljson](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-client-tools.md#os-x)
1. [Install kubectl](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-client-tools.md#os-x-1)
1. Clone this repo
1. Execute ./create-cluster
1. Wait a long time

Upon completion you should see the `kubectl get componentstatus` and `kubectl
get nodes` output that shows the cluster is ready for action.

## My Goal

The goal for me was to raise my level of knowledge around the inner workings of
Kubernetes. I am absolutely certain that if I followed Kelsey's guide to the
letter it would work perfectly every time. So, I added some challenges to raise
the difficulty level. The goal is to build a 3 controller, 3 worker Kubernetes
cluster using docker-machine. More on that later.

I chose to learn by following Kelsey's guide as inspiration. You, dear reader,
will not likely learn much by watching this script run. I recommend walking
through Kelsey's guide instead.

## Non-goals

This is not an attempt to provide a real Kubernetes automation solution. This
should **NOT** be used in production. I'm not entirely sure it should be used
in dev either. If you want a local Kubernetes development environment, check
out [Minikube](https://github.com/kubernetes/minikube). That being said; if you
want to test on a local Kubernetes setup with real cross-host networking
configured, maybe this is useful.

## The Challenges

A while back I created a set of scripts for testing with Docker Swarm Mode. The
[Swarm Mode Scripts](https://github.com/raykrueger/docker-swarm-mode-scripts)
project helped me learn how to build a swarm cluster. I used that as inspiration here.

### Use docker-machine to build the VMs

When I built my Swarm Mode Scripts package I was fascinated with how easy to
use [docker-machine](https://docs.docker.com/machine/) was. I decided that I
would use docker-machine here to build all the hosts. Knowing full well that
the VMs docker-machine produced would be [boot2docker](http://boot2docker.io/)
based. If you're not familiar, boot2docker is a
[tinycore](http://www.tinycorelinux.net/welcome.html) based Linux distribution.
The boot2docker distribution is built with only just enough to run Docker,
that's it. Which means configuring it to run Kubernetes will be a problem.

### Use containers as much as possible

I wanted to run as many components as I could as containers. Etcd,
kube-apiserver, kube-controller, and kube-scheduler are running in containers.
I had kube-proxy running in a container as well, but I was having so many
networking problems I moved to a daemon. Though, I know now that was not the
problem. The kubelet is running as a daemon too, that was just a battle not
worth having. I'll probably go back and try again on both of those.

### Networking

I don't have a cloud routing layer at my disposal. So the network routing is
done with route entries on each worker node. As well as changing several
parameters in the kubelet and kube-proxy configurations. In Kelsey's setup he
has a load balancer, I don't. I thought about building another host to act as a
load balancer, but decided that was just too much. My cluster therefore lacks
"real" HA as everything is just pointed at controller-0 for now.

### Libraries and tooling

This is directly related to running on tinycore. Getting the right libraries
and binaries in place was a huge problem. First off, the boot2docker devs got
cute and changed the uname kernel values. That results in tce-load installs
failing for things like iptables and netfilter. I had to put in a hack to the
tce-load script to hardcode a KERNELVERSION that works.

Secondly, the nsenter binary is required on the workers. There doesn't seem to
be an easy place to get that binary from. So I followed the
[nsenter](https://github.com/jpetazzo/nsenter) build instructions and used
local docker.

The rest of the Kubernetes binaries are simply downloaded using wget and
distributed to the VMs as needed. This is all done differently on the
controllers vs the workers, I intend to clean that up later.

## The Result

If you clone this repo, install the needed clients on your mac, and run the
`create-cluster` script; you should have a full cluster built... after several
minutes. This script takes a long time to run. I am also building 6 2gb virtual
hosts, each with a few gigs of disk space. This setup is a beast, so make sure
you've got the capacity.

Once everything is said and done, kubectl should work against the local cluster
and you should be able to do all the fantastic things you expect to do with
Kubernetes. At least, until you run out of memory or disk space :)

## Caveats

I do not think I am that great at bash scripting. There are definitely better
ways of doing what I've done here. This is also not complete, by any means.
There's refactoring I'd like to do, things I'd like to clean up (like any sense
of error handling).

Again, my goal was to learn by getting to a reproducible end.

## Thank You

I just wanted to say Thank you to Kelsey Hightower. He is a brilliant person
who puts an amazing amount of time and dedication in to these communities. I
thought I knew enough about Kubernetes to get by, now I am downright dangerous.
Thank you Kelsey.
