# tekton dashboard helm chart

## Setup
First add the JayeX chart repository

```sh
helm repo add jxgh https://jenkins-x.github.io/tekton-dashboard-helm-chart/
```
If it already exists be sure to update the local cache
```
helm repo update
```

## Basic install
```
helm upgrade --install tekton-dashboard jxgh/tekton-dashboard-helm-chart
```

## Exposure & authentication

There are two independent exposure choices, plus the optional bundled
[oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) for authentication:

1. **How the dashboard is exposed** — an `Ingress` (`ingress.enabled`) **or** the
   Gateway API (`gateway.enabled`, which renders an `HTTPRoute` and, when
   `gateway.auth.enabled`, an Envoy Gateway `SecurityPolicy`). `gateway.parentRefs`
   defaults to the Envoy Gateway in `envoy-gateway-system`; override it for a custom
   gateway.
2. **How oauth2-proxy is exposed** (only when `oauth2-proxy.enabled`) — its own
   `Ingress` (`oauth2-proxy.ingress.enabled`) **or** `HTTPRoute`
   (`oauth2-proxy.gatewayApi.enabled`).

The dashboard's auth mechanism follows how the **dashboard** is exposed:

| Dashboard via | Auth mechanism | Configured by |
|---|---|---|
| Ingress | nginx `auth-url` / `auth-signin` annotations | `authHost` |
| Gateway (`gateway.auth.type: extAuth`) | Envoy Gateway `SecurityPolicy` (`extAuth` → oauth2-proxy Service) | `gateway.auth.enabled` + `gateway.auth.extAuth.*` (requires Envoy Gateway) |
| Gateway (`gateway.auth.type: oidc`) | Envoy Gateway `SecurityPolicy` (native `oidc`, no oauth2-proxy) | `gateway.auth.enabled` + `gateway.auth.oidc.*` (requires Envoy Gateway) |

Auth is opt-in: with `gateway.enabled` alone, the dashboard is routed without auth.
When `gateway.auth.enabled` is set, `type` defaults to `oidc` (Envoy Gateway handles OIDC flow; no oauth2-proxy required).

Set `type: extAuth` to delegate auth to an external provider.

It's recommended that the dashboard and auth provider share the same data plane (Ingress or Gateway API) to avoid complexity and potential issues with cookie domains, CORS, etc.