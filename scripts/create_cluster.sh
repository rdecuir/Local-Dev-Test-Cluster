# Add and Update Helm repo
# istio
# argocd
# etc

helm install --create-namespace argocd --values /argocd/argocd.yaml (Application)
k apply -n argocd -f {manifests} -R
k apply -n argocd -f {apps/root-app}

k port-forward servce/argo-argocd-server -n argocd 8081:443

