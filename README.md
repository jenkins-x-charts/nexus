## Sonatype Nexus 3.x Chart

Nexus is a repository for storing and caching artifacts.  Based on the initial work done upstream in the kubernetes chart repo [here](https://github.com/kubernetes/charts/tree/1516468/stable/sonatype-nexus).

This chart is deployed when installing Jenkins X on a Kubernetes cluster.  Refer to the [Jenkins X Documentation](https://jenkins-x.io/docs/) for more information.

## Updates added
Forked nexus to add Docker repository and endpoints to the jenkinsx nexus service

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

  helm repo add softtech https://softtechconsulting.github.io/nexus

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
softtech` to see the charts.

To install the nexus chart:

    helm install nexus softtech/nexus

To uninstall the chart:

    helm delete nexus