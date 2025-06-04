# Istio

https://brettmostert.medium.com/k3d-kubernetes-istio-service-mesh-286a7ba3a64f

https://github.com/rajasoun/k3d-istio

https://github.com/adavarski/k3d-istio-playground

## Two install options:
### istioctl

The simplest and most qualified installation and management path with high security. This is the community recommended method for most use cases.

Pros:

Thorough configuration validation and health verification.
Uses the IstioOperator API which provides extensive configuration/customization options.

Cons:

Multiple binaries must be managed, one per Istio minor version.
The istioctl command can set values automatically based on your running environment, thereby producing varying installations in different Kubernetes environments.

### helm 
Allows easy integration with Helm-based workflows and automated resource pruning during upgrades.

Pros:

Familiar approach using industry standard tooling.
Helm native release and upgrade management.

Cons:

Fewer checks and validations compared to istioctl install.
Some administrative tasks require more steps and have higher complexity.

**SELECTION: Going with what is already in place, and consider the community recommended method.**

## Instructions

1. Find out architecture: `uname -m`, in my case arm64

1. Download the binary:
  1. `curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.0 TARGET_ARCH=arm64 sh -`
