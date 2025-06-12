# SS

https://github.com/bitnami-labs/sealed-secrets

```
KUBESEAL_VERSION='' # Set this to, for example, KUBESEAL_VERSION='0.23.0'
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION:?}/kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz"
tar -xvzf kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

### For Me...
```
brew install kubeseal
```

### Process
```
kubectl --namespace default \
    create secret \
    generic mysecret \
    --dry-run=client \
    --from-literal foo=bar \
    --output yaml

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

### Sealing Flow:
```
# Build secret, the data must be base64 encoded

kubeseal --fetch-cert --controller-name=sealed-secrets-controller --controller-namespace=sealed-secrets > ss.pem

kubeseal --cert ss.pem < test-secret.yaml > apps/secrets/SEALED-test-secret.yaml

kubectl get secret test-secret.yaml -n secrets -o jsonpath="{.data.superSecretPassword}" | base64 --decode
```

### Saving Sealing Key
```
kubectl -n sealed-secrets get secret sealed-secrets-{} -o yaml > sealed-secrets-key.yaml

```