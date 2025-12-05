# Minio

Looks like the tenant console is causing problems in the whole coder being weird environment so I am now working im my space as I have tighter control

Yup it works here, so wasted a day trying to get it to work in coder

## Does it work this way for user, bucket, and policy creation
```
apiVersion: operator.min.io/v1
kind: MinioPolicy
metadata:
  name: my-bucket-read-policy
  namespace: minio-tenant-namespace # Replace with your tenant's namespace
spec:
  tenant: my-minio-tenant # Replace with your MinIO tenant name
  name: read-only-policy
  policy: |
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetObject",
            "s3:ListBucket"
          ],
          "Resource": [
            "arn:aws:s3:::my-secure-bucket",
            "arn:aws:s3:::my-secure-bucket/*"
          ]
        }
      ]
    }
```
```
apiVersion: operator.min.io/v1
kind: MinioServiceAccount
metadata:
  name: my-app-user
  namespace: minio-tenant-namespace # Replace with your tenant's namespace
spec:
  tenant: my-minio-tenant # Replace with your MinIO tenant name
  user: my-app-username
  secretRef:
    name: my-app-user-secret # A Kubernetes secret to store AccessKey and SecretKey
  policies:
    - read-only-policy # Link to the policy created above
```
```
apiVersion: v1
kind: Secret
metadata:
  name: my-app-user-secret
  namespace: minio-tenant-namespace # Replace with your tenant's namespace
type: Opaque
stringData:
  AccessKey: YOUR_ACCESS_KEY
  SecretKey: YOUR_SECRET_KEY
```
```
apiVersion: operator.min.io/v1
kind: MinioBucket
metadata:
  name: my-secure-bucket
  namespace: minio-tenant-namespace # Replace with your tenant's namespace
spec:
  tenant: my-minio-tenant # Replace with your MinIO tenant name
  name: my-secure-bucket
  region: us-east-1
```



LOOK for buckets:[] in the tenant and also find the spec somewhere try "helm show crd minio/tenant" something something .buckets
