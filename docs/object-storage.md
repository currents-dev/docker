# Use AWS S3 for Artifact Storage

Currents stores test artifacts (screenshots, videos, Playwright traces, stdout and attachments) in an S3-compatible bucket. This page covers the bucket permissions and CORS rules Currents needs when you use AWS S3 instead of the included RustFS service.

## How Artifacts Reach the Bucket

Objects in the bucket stay private. Currents never makes them public and doesn't need a bucket policy that grants public access.

- **Uploads:** when a test run records, the director hands the CI reporter short-lived signed `PUT` URLs, and the reporter uploads directly to the bucket. The director also uploads stdout itself.
- **Reads:** when someone opens a test in the dashboard, the API signs a short-lived `GET` URL, and the browser downloads from the bucket directly. Playwright traces open in [trace.playwright.dev](https://trace.playwright.dev), which also downloads the trace from the bucket.

Every signed URL is signed with the `FILE_STORAGE_ACCESS_KEY_ID` / `FILE_STORAGE_SECRET_ACCESS_KEY` credentials and can only do what that IAM identity is allowed to do.

## Configuration

```bash
FILE_STORAGE_ENDPOINT=https://s3.us-east-1.amazonaws.com
FILE_STORAGE_INTERNAL_ENDPOINT=https://s3.us-east-1.amazonaws.com
FILE_STORAGE_REGION=us-east-1
FILE_STORAGE_BUCKET=currents-artifacts
FILE_STORAGE_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
FILE_STORAGE_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

The values above are AWS's documentation examples. Use an access key for the IAM user that has the [IAM policy](#iam-policy) below. Create one in the IAM console (**Users → *user* → Security credentials → Create access key**) or with the AWS CLI, replacing `currents-storage` with the IAM user name:

```bash
aws iam create-access-key --user-name currents-storage
```

- `FILE_STORAGE_REGION` must be the bucket's region, and `FILE_STORAGE_ENDPOINT` that region's S3 endpoint. Signed URLs for any other region are rejected.
- Set `FILE_STORAGE_INTERNAL_ENDPOINT` to the same endpoint. `.env.example` points it at the included RustFS service, and the director uploads stdout through it.
- Leave `FILE_STORAGE_FORCE_PATH_STYLE` unset for AWS S3.

## IAM Policy

Attach this policy to the IAM user or role whose credentials are in `FILE_STORAGE_ACCESS_KEY_ID` / `FILE_STORAGE_SECRET_ACCESS_KEY`. Replace `currents-artifacts` with your bucket name.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject"],
      "Resource": "arn:aws:s3:::currents-artifacts/*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::currents-artifacts"
    }
  ]
}
```

`s3:ListBucket` lets S3 answer `404 Not Found` for a missing object. Without it, S3 answers `403 Access Denied`, so a missing artifact looks like a permissions problem.

If the bucket uses SSE-KMS with a customer-managed key, also allow `kms:GenerateDataKey` (for uploads) and `kms:Decrypt` (for downloads) on that key for the same identity. The key policy must allow that identity too, either directly or with the default statement that lets IAM policies grant access to the key. Otherwise uploads and downloads fail with `AccessDenied`.

## CORS Configuration

The dashboard downloads stdout and attachment previews from the browser, and trace.playwright.dev downloads traces from the browser. Both are cross-origin requests to the bucket, so the bucket needs a CORS rule that allows the Currents dashboard origin and trace.playwright.dev:

```json
[
  {
    "AllowedOrigins": ["https://currents.example.com", "https://trace.playwright.dev"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["Content-Length", "Content-Range", "ETag"],
    "MaxAgeSeconds": 3000
  }
]
```

Replace `https://currents.example.com` with your `APP_BASE_URL`, without a trailing slash. Apply it in the S3 console (**Bucket → Permissions → Cross-origin resource sharing (CORS)**) or with the AWS CLI. The CLI expects the rule wrapped in a `CORSRules` key. Replace `currents-artifacts` with your bucket name:

```bash
aws s3api put-bucket-cors --bucket currents-artifacts --cors-configuration '{
  "CORSRules": [
    {
      "AllowedOrigins": ["https://currents.example.com", "https://trace.playwright.dev"],
      "AllowedMethods": ["GET", "HEAD"],
      "AllowedHeaders": ["*"],
      "ExposeHeaders": ["Content-Length", "Content-Range", "ETag"],
      "MaxAgeSeconds": 3000
    }
  ]
}'
```

Uploads come from the CI reporter and from Currents services rather than a browser, so they don't need a CORS rule.

## Troubleshooting 403 Errors

Open the failing request in the browser's developer tools (**Network** tab):

| What you see | Cause | Fix |
|---|---|---|
| The console reports a CORS error, or the request fails on traces and stdout while screenshots and videos load | No CORS rule for the requesting origin | Add the [CORS configuration](#cors-configuration), including `https://trace.playwright.dev` |
| `<Code>AccessDenied</Code>` on a URL with `X-Amz-Signature` in the query string | The `FILE_STORAGE_*` identity can't read the object, the KMS key doesn't allow decrypting, or the object doesn't exist and `s3:ListBucket` is missing | Apply the [IAM policy](#iam-policy) |
| `<Code>AccessDenied</Code>` on a URL without `X-Amz-Signature` | The object URL was opened directly instead of through the dashboard | Open artifacts from the dashboard. The bucket is meant to stay private |
| `<Code>SignatureDoesNotMatch</Code>` or `AuthorizationQueryParametersError` | Wrong credentials, region or endpoint | Check `FILE_STORAGE_REGION` and `FILE_STORAGE_ENDPOINT` match the bucket |
| `<Code>AccessDenied</Code>` with `Request has expired` | The signed URL is older than its expiry, or the host clock is off | Reload the page in the dashboard, and check the Docker host's clock |
