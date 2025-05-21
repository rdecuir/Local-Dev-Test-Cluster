# SS

https://github.com/bitnami-labs/sealed-secrets

1. Install `kubeseal` CLI from https://github.com/bitnami-labs/sealed-secrets

1. 
    ```
    kubectl apply \
    --filename https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.13.1/controller.yaml
    ```

### Process
```
kubectl --namespace default \
    create secret \
    generic mysecret \
    --dry-run=client \
    --from-literal foo=bar \
    --output json

kubectl --namespace default \
    create secret \
    generic mysecret \
    --dry-run=client \
    --from-literal foo=bar \
    --output json \
    | kubeseal \
    | tee mysecret.yaml

kubectl create \
    --filename mysecret.yaml

kubectl get secret mysecret \
    --output yaml

kubectl get secret mysecret \
    --output jsonpath="{.data.foo}" \
    | base64 --decode && echo

kubeseal --fetch-cert
```