# OpenShift Cluster Bootstrap

This project is designed to bootstrap an OpenShift cluster with several operators and components that are utilized for Machine Learning.

The bootstrap script inside this repo will configure cluster level resources, primarily the various operators. This repo is intended to be reusable for different demos and contain a core set of OpenShift features that would commonly be used for a Data Science environment.

Several key resources are also configured, such as OpenShift-GitOps and Sealed Secrets.  Once the initial components are deployed, several ArgoCD Application objects are created which are then used to install and manage the install of the operators on the cluster.

One important feature of this repo is that it depends on a Sealed Secret master key which cannot be checked into git. If you already have a master key on your local machine it will automatically utilize that key when deploying Sealed Secrets. If a key is not present, the bootstrap script will prompt you before deploying Sealed Secrets, and saving a master key to your local machine for future reuse.  If any of your GitOps repos deploy a Sealed Secret object you must have the correct master key to unseal those objects, which means you may need to get the key from the user that initially sealed the secret.

## Components

This repository will configure the following items.

### Operators

- AMQ-Streams Operator
- Crunchy Postgres Operator
- Elasticsearch Operator
- Grafana Operator
- OpenDataHub Operator
- OpenShift Data Foundations Operator
- OpenShift GitOps Operator
- OpenShift Logging Operator
- OpenShift Pipelines Operator
- OpenShift Serverless Operator
- Sealed Secrets Operator
- Seldon Operator
- Web Terminal Operators

### Additional Configurations

- OpenShift Monitoring - User Workload Monitoring

## Prerequisites

### Client Tooling

The bootstrap script relies on the following command line tools. If they're not already available on your system path, the bootstrap script will attempt to download them from the internet, and will place then in a `.\tmp` folder location where the bootstrap script was run:

- [oc](https://docs.openshift.com/container-platform/4.11/cli_reference/openshift_cli/getting-started-cli.html) - the OpenShift command-line interface (CLI) that allows for creation of applications, and can manage OpenShift Container Platform projects from a terminal.

- [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/) - a Kubernetes configuration transformation tool that enables you to customize un-templated YAML files, leaving the original files untouched.

- [kubeseal](https://github.com/bitnami-labs/sealed-secrets#installation) - uses asymmetric crypto to encrypt secrets that only the controller can decrypt. These encrypted secrets are encoded in a SealedSecret resource, which you can see as a recipe for creating a secret.

- [openshift-install](https://github.com/openshift/installer/releases) (optional) - tooling that could be used for monitoring the [cluster installation progress](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.11/html/installing/installing-on-a-single-node#install-sno-monitoring-the-installation-manually_install-sno-installing-sno-with-the-assisted-installer).

### Access to an OpenShift Cluster

Before running the bootstrap script, ensure that you have login access to your OpenShift cluster. This OpenShift cluster may have been provisioned though [RHDS](https://demo.redhat.com), or it may also be your own custom built cluster running on dedicated hardware.

Make sure you are [logged into your cluster](https://docs.openshift.com/online/pro/cli_reference/get_started_cli.html) using the `oc login ...` command.  You can obtain a login token if required by utilizing the "Copy Login Command" found under your user profile in the OpenShift Web Console.

The scripts require a user with sufficient permissions for installing and configuring operators, typically the `opentlc-mgr` user account on a Red Hat Demo System hosted cluster.


## Bootstrapping a Cluster

Clone this git repository to a directory location on your local workstation.

### Sealed Secrets

This repository deploys sealed-secrets and requires a sealed secret master key to during the bootstrap process. 

> **_NOTE:_** This repo does not does not deploy any Sealed Secrets, it's goal is to simply setup the Sealed Secrets operator to enable future use.  If you plan to deploy any additional repos containing Sealed Secrets, consider updating the `sealed-secrets-secret.yaml` file with the master key to unseal those Sealed Secrets.  If you do not plan on deploying any Sealed Secrets, you can follow the prompts to allow the script to generate an initial master key for you.

The script will prompt: "Create NEW bootstrap/base/sealed-secrets-secret.yaml? [y/N]", you should answer:

| Answer | Description |
| ------ | ----------- |
| Yes    | Choose this option if this is a brand new project, and you do not have any Sealed Secrets you plan to deploy. The bootstrap script will generate a new sealed secrets yaml file containing the master key generated by the sealed-secrets controller. |
| No     | If your cluster already has a sealed secrets master key, you should copy it into to the `bootstrap/base/sealed-secrets-secret.yaml`. Also, if you've re-running the bootstrap script, this sealed secret file already exists. |
| -      | If you have already previously run the bootstrap script, your local copy of the repo will already contain the `bootstrap/base/sealed-secrets-secret.yaml` file and you will not be prompted to create a master key. If you do not want to re-use a master key on the new cluster, consider removing the `bootstrap/base/sealed-secrets-secret.yaml` file before re-executing the boot script. |

Note that the sealed-secrets-secret.yaml file is explicitly excluded from being checked into git in the `.gitignore` file, this is because it contains sensitive data (the master key) which should NOT be stored in source control.


### Run the Cluster Bootstrap

Execute the bootstrap script to begin the installation process:

```sh
./scripts/bootstrap.sh
```

When prompted to select a bootstrap folder, choose the overlay that matches your cluster version, for example: `bootstrap/overlays/rhpds-4.11/`.

The `bootstrap.sh` script will now install the OpenShift GitOps Operator, create an ArgoCD instance once the operator is deployed in the `openshift-gitops` namespace, then bootstrap a set of ArgoCD applications to configure the cluster.

Once the script completes, verify that you can access the ArgoCD UI using the URL output by the last line of the script execution. This URL should present an ArgoCD login page, showing that it was successfully deployed.

Alternatively you can also obtain the ArgoCD login URL from the ArgoCD route:

```sh
oc get routes openshift-gitops-server -n openshift-gitops
```

Use the OpenShift Login option and sign in with your OpenShift credentials.

The cluster may take 10-15 minutes to finish installing and updating.

## Project Structure Overview

This project structure is based on the opinionated configuration found [here](https://github.com/gnunn-gitops/standards/blob/master/folders.md).  For a more detailed breakdown of the intention of this folder structure, feel free to read more there.

### Bootstrap

The bootstrap folder contains the initial set of resources utilized to deploy the cluster.

### Clusters

Clusters is the main aggregation layer for all of the elements of the cluster.  It also contains the main configuration elements for changing the repo/branch of the project.

### Components

Components contains the bulk of the configuration.  Currently we are utilizing two main folders inside of `components`:

- argocd
- operators

The opinionated configuration referenced above recommends several other folders in the `components` folder that we are not utilizing today but may be useful to add in the future.

#### ArgoCD

The argocd folder contains the ArgoCD specific objects needed to configure the items in the apps folder.  The folders inside of Argo represent the different custom resources ArgoCD supports and refer back to objects in the `apps` folder.

#### Operators

Operators contain the operators we wish to configure on the cluster and the details of how we would like them to be configured.

The operators folder general follows a pattern where each folder in `operators` is intended to be a separate ArgoCD application.  The majority of the folder structure utilized inside of those folders is a direct reference to the [redhat-cop/gitops-catalog](https://github.com/redhat-cop/gitops-catalog).  When attempting to add new operators to the cluster, be sure to check there first and feel free to contribute new components back to the catalog as well!

## Updating the ArgoCD Groups

Argo creates the following group in OpenShift to grant access and control inside of ArgoCD:

- gitopsadmins

To add a user to the admin group run:

```sh
oc adm groups add-users gitopsadmins $(oc whoami)
```

To add a user to the user group run:

```sh
oc adm groups add-users argocdusers $(oc whoami)
```

Once the user has been added to the group logout of Argo and log back in to apply the updated permissions.

Can you validate that you have the correct permissions by going to `User Info` menu inside of Argo.

## Accessing Argo using the CLI

To log into ArgoCD using the `argocd` cli tool run the following command:

```sh
argocd login --sso <argocd-route> --grpc-web
```

## ArgoCD Troubleshooting

### Operator Shows Progressing for a Very Long Time

ArgoCD Symptoms:

Argo Applications and the child subscription object for operator installs show `Progressing` for a very long time.

Explanation:

Argo utilizes a `Health Check` to validate if an object has been successfully applied and updated, failed, or is progressing by the cluster.  The health check for the `Subscription` object looks at the `Condition` field in the `Subscription` which is updated by the `OLM`.  Once the `Subscription` is applied to the cluster, `OLM` creates several other objects in order to install the Operator.  Once the Operator has been installed `OLM` will report the status back to the `Subscription` object.  This reconciliation process may take several minutes even after the Operator has successfully installed.

Resolution/Troubleshooting:

- Validate that the Operator has successfully installed via the `Installed Operators` section of the OpenShift Web Console.
- If the Operator has not installed, additional troubleshooting is required.
- If the Operator has successfully installed, feel free to ignore the `Progressing` state and proceed.  `OLM` should reconcile the status after several minutes and Argo will update the state to `Healthy`.
