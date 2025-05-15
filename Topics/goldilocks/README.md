# FairwindsOps Goldilocks

Whats is Goldilocks: 
- https://www.youtube.com/watch?v=YiwMIB6A2tc
- https://www.fairwinds.com/blog/introducing-goldilocks-a-tool-for-recommending-resource-requests

## Testing steps

1. `helm repo add fairwinds-stable https://charts.fairwinds.com/stable`

1. `k create ns goldilocks`

1. `helm install goldilocks fairwinds-stable/goldilocks --namespace goldilocks`

1. `helm install vpa fairwinds-stable/vpa --namespace vpa --create-namespace`

1. `k label ns goldilocks goldilocks.fairwinds.com/enabled=true`

1. `k label ns nginx goldilocks.fairwinds.com/enabled=true`

## Deploying by way of argo (For Now)
1. Initial argocd start up
1. `k apply -f argo-apps/goldilocks.yaml`
1. `kubectl port-forward -n goldilocks svc/goldilocks-dashboard 4433:80`
1. Add label and check that a vpa has be created for defined namespace to monitor the workloads in that name space (Workload=Deployment/StatefulSets/DaemonSet)
1. NOTE: Understand that once a label is added to a namespace, it does take a bit to build te initial recommendations