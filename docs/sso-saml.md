# Enable SAML SSO

Currents on-prem can delegate sign-in to your SAML 2.0 identity provider (Okta, Microsoft Entra ID, Google Workspace, etc.). Once enabled, users sign in **email-first**: they enter their email, are redirected to your IdP to authenticate, and on return are automatically provisioned into your organization.

SSO turns on automatically once the two required variables are set and the IdP metadata file is mounted.

## Prerequisites

- A running on-prem deployment (see the [Quickstart Guide](./quickstart.md)).
- **SMTP configured** — email is used for account provisioning and invitations. See the [SMTP Configuration](./quickstart.md#smtp-configuration) section.
- Admin access to your identity provider to create a SAML application.

## Step 1 — Choose two identifiers

You'll reuse these in both your IdP and your `.env`:

- **Provider id** (`SSO_SAML_PROVIDER_ID`) — set it to your IdP's service name, e.g. `okta`. It becomes the last path segment of the callback URL.
- **Issuer** (`SSO_SAML_ISSUER`) — a **stable, opaque** identifier that names this deployment as a SAML Service Provider. Use the form `currents-onprem:<your-org>`, e.g. `currents-onprem:acme`.

> ⚠️ **The issuer is not a URL.** Use a stable string like `currents-onprem:acme`. It only has to match the "Audience / SP Entity ID" you enter in your IdP — it does not need to resolve, and using your deployment URL is discouraged because that URL can change.

## Step 2 — Create the SAML app in your IdP

Create a new **SAML 2.0** application. Using Okta as the example, set:

| IdP field | Value |
|-----------|-------|
| **Single Sign-On URL** (a.k.a. ACS / Assertion Consumer Service URL) | `<APP_BASE_URL>/api/auth/sso/saml2/callback/okta` |
| **Audience URI** (a.k.a. SP Entity ID) | `currents-onprem:acme` |
| **Name ID format** | `Persistent` |
| **Application username** | Email |

Replace `<APP_BASE_URL>` with your deployment's base URL (the value of `APP_BASE_URL` in your `.env`, e.g. `https://currents.acme.com`), `okta` with your `SSO_SAML_PROVIDER_ID`, and `currents-onprem:acme` with your `SSO_SAML_ISSUER`.

Then **download the application's IdP metadata XML** (in Okta: the app's *Metadata URL*, or *SAML Setup Instructions → Identity Provider metadata*). This one file contains the IdP sign-on URL, entity ID, and signing certificate — Currents reads all of them from it.

## Step 3 — Provide the metadata file

Drop the metadata XML into `./data/sso` (bind-mounted read-only into the API container at `/etc/currents/sso`):

```bash
mkdir -p ./data/sso
cp ~/Downloads/okta-metadata.xml ./data/sso/idp-metadata.xml
```

## Step 4 — Configure and restart

Add the following to your `.env`:

```bash
# Required
SSO_SAML_IDP_METADATA_FILE=/etc/currents/sso/idp-metadata.xml
SSO_SAML_ISSUER=currents-onprem:acme

# Recommended
SSO_SAML_PROVIDER_ID=okta
```

Restart the stack to apply:

```bash
docker compose up -d
```

## Step 5 — Sign in

Go to your dashboard and enter your email on the sign-in screen. If your email is not the root admin's local password account, you'll be redirected to your IdP; after authenticating you'll be returned and provisioned into the organization.

> New SSO users are added to your single on-prem organization automatically, with the role set by `SSO_SAML_DEFAULT_ROLE` (default `member`). The root admin account continues to sign in with its email + password.

## Optional configuration

| Variable | Purpose |
|----------|---------|
| `SSO_SAML_DEFAULT_ROLE` | Role for auto-provisioned SSO users. Default `member`. |
| `SSO_ALLOWED_DOMAINS` | Comma-separated allow-list of email domains, e.g. `acme.com,acme.io`. Defense-in-depth on top of your IdP. |
| `SSO_SAML_AUTHN_REQUESTS_SIGNED` | Set `true` to sign outbound AuthnRequests. Requires an SP key/cert (below). |
| `SSO_SAML_SP_CERT_FILE` / `SSO_SAML_SP_KEY_FILE` | Paths to your SP certificate/private key PEMs (place them in `./data/sso` too). Only needed for signed requests. |

### Signing AuthnRequests (advanced)

If your IdP requires signed requests, generate a self-signed SP keypair, drop it in `./data/sso`, and point the vars at it:

```bash
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout ./data/sso/sp-key.pem -out ./data/sso/sp-cert.pem -days 825 \
  -subj "/CN=currents-onprem"
```

```bash
SSO_SAML_AUTHN_REQUESTS_SIGNED=true
SSO_SAML_SP_CERT_FILE=/etc/currents/sso/sp-cert.pem
SSO_SAML_SP_KEY_FILE=/etc/currents/sso/sp-key.pem
```

## Rotating the IdP certificate

The metadata file is the single source for the IdP sign-on URL, entity ID, and signing certificate. To rotate the IdP's signing certificate, download the refreshed metadata XML, replace `./data/sso/idp-metadata.xml`, and restart the API — no other configuration changes are needed.

## Troubleshooting

- **Sign-in isn't redirecting to the IdP** — confirm both `SSO_SAML_IDP_METADATA_FILE` and `SSO_SAML_ISSUER` are set and the file exists at the mounted path; SSO is off until both are present. Check the API logs at startup for SSO config validation errors.
- **IdP rejects the request / "audience mismatch"** — the **Audience / SP Entity ID** in your IdP must exactly equal `SSO_SAML_ISSUER`.
- **Assertion signature invalid** — the metadata XML is stale or from the wrong app; re-download it from the IdP and replace the file.

See the [Configuration Reference](./configuration.md#saml-sso-optional) for the full list of SSO variables.
