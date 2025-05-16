# Directory Restructure
/apps
- /{apps}
-- /templates
-- /files
-- values.yaml (common)
-- values-dev.yaml
-- values-prod.yaml
-- Chart.yaml

/argo-apps
- {apps}.yaml - Argo Application yaml files

/argo? - Project Manifests?

```
  sources:
    # Case 1 - Helm Charts 
    ## Deploying the actual helm chart itself w/ custom values to overwite default.yaml     
    - repoURL: https://charts.fairwinds.com/stable
      chart: goldilocks
      targetRevision: 9.0.2
      helm:
        valueFiles:
          - $values/apps/goldilocks/values.yaml                         # global values across all envs
          - $values/apps/goldilocks/values-${CI_ENVIROMENT_NAME}.yaml   # env specific values
    
    ## Deploying manifests needed in addition to the helm chart, this includes templated manifests
    - path: apps/goldilocks
      repoURL: https://github.com/rdecuir/Local-Dev-Test-Cluster
      targetRevision: main
      directory:
        recurse: true
    ### TEST THIS - idea is to have an "alias" or some thing so that manifest templating doesnt affect the helm chart templating so ".Value.custom.template.foo"other wise you could include a chart dir instead of a templates dir.

    # Case 2 - Custom Chart 
```