# mcp-server-everything-wrong Helm chart

Deploys the [mcp-server-everything-wrong](../../README.md) demo server into
its own namespace on an existing Kubernetes cluster.

> [!CAUTION]
> This deploys an **intentionally insecure** demo server (arbitrary command
> execution, environment-variable dumping, unrestricted outbound fetches).
> Never install it on a cluster reachable by anyone untrusted.

## Install

> [!NOTE]
> `--set` on a single field of a list item (like `ingress.hosts[0].host`)
> replaces the whole list-item map, silently dropping its sibling fields
> (`paths`) and rendering an Ingress Kubernetes will reject (`paths`
> requires at least one entry). Put anything under `ingress.hosts` in a
> values file instead, as shown below — `--set` stays fine for the flat
> scalars (`image.*`, `auth.token`, `ingress.ingressClassName`).

Create `overrides.yaml`:

```yaml
ingress:
  hosts:
    - host: mcp.your-domain.example
      paths:
        - path: /mcp
          pathType: Prefix
  ingressClassName: <your-ingress-class>
```

> [!CAUTION]
> `ingress.enabled` defaults to `true` with `ingress.tls` empty — installing
> with only the override above publishes this server over plain HTTP, which
> sends the `Authorization: Bearer <token>` header in cleartext. Either set
> `ingress.tls` (standard `Ingress.spec.tls` shape) or rely on a
> TLS-terminating ingress controller/gateway in front of it; never expose
> this server over plain HTTP beyond a trusted network.

Then install — from the published OCI chart (no source checkout needed):

```console
kubectl create namespace mcp-everything-wrong --dry-run=client -o yaml | kubectl apply -f -
# or: helm install ... --create-namespace (see below)

helm install everything-wrong oci://<your-chart-registry>/charts/mcp-server-everything-wrong \
  --version 0.1.0 \
  -n mcp-everything-wrong --create-namespace \
  -f overrides.yaml \
  --set image.repository=<your-registry>/mcp-server-everything-wrong \
  --set image.tag=<tag> \
  --set auth.token="$(openssl rand -hex 32)"
```

`<your-chart-registry>/charts/mcp-server-everything-wrong` (the chart) and
`<your-registry>/mcp-server-everything-wrong` (the image) are two separate
artifacts in two separate registry paths — see [Publishing this
chart](#publishing-this-chart) below for how the chart gets there. Until
it's published, install straight from a checkout instead:

```console
helm install everything-wrong ./helm/mcp-server-everything-wrong \
  -n mcp-everything-wrong --create-namespace \
  -f overrides.yaml \
  --set image.repository=<your-registry>/mcp-server-everything-wrong \
  --set image.tag=<tag> \
  --set auth.token="$(openssl rand -hex 32)"
```

## Key values

| Key | Description | Default |
| --- | --- | --- |
| `image.repository` / `image.tag` | Where to pull the image from. No default — required. | `""` |
| `auth.token` | Required `MCP_AUTH_TOKEN`. Generate with `openssl rand -hex 32`. | `""` |
| `replicaCount` | Fixed at `1` — do not scale up (see chart comments: the `greet` demo relies on single-process state). | `1` |
| `ingress.enabled` / `ingress.hosts` / `ingress.ingressClassName` | Ingress exposure. No controller-specific annotations assumed. | `true` / `[{host: "", paths: [...]}]` / `""` |
| `networkPolicy.enabled` | Opt-in NetworkPolicy restricting ingress to same-namespace + `networkPolicy.allowedIngressNamespaces`. Egress is never restricted (the `fetch` tool needs it). | `false` |

See `values.yaml` for the full set of overridable values.

## Verifying a rendered install without applying it

```console
helm lint ./helm/mcp-server-everything-wrong
helm template everything-wrong ./helm/mcp-server-everything-wrong \
  --set auth.token=test --set image.repository=x --set image.tag=y \
  | kubectl apply --dry-run=client -f -
```

## Publishing this chart

One-time (or per-registry-session) login:

```console
helm registry login <your-chart-registry>
```

Package and push a new version (bump `version` in `Chart.yaml` first if this
isn't the first publish):

```console
helm package ./helm/mcp-server-everything-wrong
helm push mcp-server-everything-wrong-0.1.0.tgz oci://<your-chart-registry>/charts
```

This pushes the *chart* only — it doesn't build, tag, or push the Docker
image. That's a separate step against `Dockerfile` in the repo root, to
whatever registry `image.repository` will point at for installers.
