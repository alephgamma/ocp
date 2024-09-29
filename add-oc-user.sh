#!/bin/bash

user=$1			# user=radmin
pass=$2			# pass=radmin

# get the X.509 Certificate and authenticate with it.
# scp lab@utility:/home/lab/ocp4/auth/kubeconfig .
# export KUBECONFIG=kubeconfig
# oc get oauth cluster -o json > oauth.yaml

oldpods="$(oc get pod -n openshift-authentication -o name)"
secret=$(oc get oauth cluster -o jsonpath='{.spec.identityProviders[0].htpasswd.fileData.name}')
tmpdir=$(mktemp -d)								# mktemp ?
oc extract secret/$secret -n openshift-config --keys htpasswd --to $tmpdir
htpasswd -b $tmpdir/htpasswd $user $pass
oc set data secret/$secret --from-file htpasswd=$tmpdir/htpasswd -n openshift-config

rm -rf $tmpdir

oc wait co/authentication --for condition=Progressing --timeout 90s		# cluster-operator / co
oc rollout status deployment oauth-openshift -n openshift-authentication --timeout 90s
oc wait $oldpods -n openshift-authentication --for delete --timeout 90s
oc login -u $user -p $pass --kubeconfig /dev/null https://api.ocp4.example.com:6443
