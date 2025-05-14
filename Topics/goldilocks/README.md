# FairwindsOps Goldilocks

1. `helm repo add fairwinds-stable https://charts.fairwinds.com/stable`

1. `k create ns goldilocks`

1. `helm install goldilocks fairwinds-stable/goldilocks --namespace goldilocks`

1. `helm install vpa fairwinds-stable/vpa --namespace vpa --create-namespace`

1. `k label ns goldilocks goldilocks.fairwinds.com/enabled=true`

1. `k label ns nginx goldilocks.fairwinds.com/enabled=true`