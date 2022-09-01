#!/bin/bash
set -e

echo "Validating cluster login"
oc whoami

LANG=C
SLEEP_SECONDS=45
ARGO_NS="openshift-gitops"

# Validate sealed secrets secret exists
SEALED_SECRETS_SECRET=./bootstrap/base/sealed-secrets-secret.yaml
if [ ! -f ${SEALED_SECRETS_SECRET} ]; then
  echo "Missing ${SEALED_SECRETS_SECRET}"
  echo "This master key is required to bootstrap sealed secrets and cannot be checked into git.  Please add this key to the repo prior to running the bootstrap."
fi

PS3="Please select a bootstrap folder: "
select bootstrap_dir in ./bootstrap/overlays/*/; 
do 
    test -n "$bootstrap_dir" && break; 
    echo ">>> Invalid Selection"; 
done

echo "Selected: ${bootstrap_dir}"

echo ""
echo "Installing GitOps Operator."

kustomize build components/operators/openshift-gitops/operator/overlays/stable/ | oc apply -f -

echo "Pause $SLEEP_SECONDS seconds for the creation of the gitops-operator..."
sleep $SLEEP_SECONDS

echo "Waiting for operator to start"
until oc get deployment gitops-operator-controller-manager -n openshift-operators
do
  sleep 5;
done

echo "Waiting for openshift-gitops namespace to be created"
until oc get ns ${ARGO_NS}
do
  sleep 5;
done

echo "Waiting for deployments to start"
until oc get deployment cluster -n ${ARGO_NS}
do
  sleep 5;
done

echo "Waiting for all pods to be created"
deployments=(cluster kam openshift-gitops-applicationset-controller openshift-gitops-redis openshift-gitops-repo-server openshift-gitops-server)
for i in "${deployments[@]}";
do
  echo "Waiting for deployment $i";
  oc rollout status deployment $i -n ${ARGO_NS}
done

echo "Apply overlay to override default instance"
kustomize build ${bootstrap_dir} | oc apply -f -

sleep 10
echo "Waiting for all pods to redeploy"
deployments=(cluster kam openshift-gitops-applicationset-controller openshift-gitops-redis openshift-gitops-repo-server openshift-gitops-server)
for i in "${deployments[@]}";
do
  echo "Waiting for deployment $i";
  oc rollout status deployment $i -n ${ARGO_NS}
done

echo ""
echo "GitOps has successfully deployed!  Check the status of the sync here:"

route=$(oc get route openshift-gitops-server -o=jsonpath='{.spec.host}' -n ${ARGO_NS})

echo "https://${route}"
