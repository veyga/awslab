# veyga-microservice

Bare-bones chart: a Deployment and a Service for one container, plus an optional
Traefik Ingress with a cert-manager certificate. Every resource is named after the release.

| Value | Default | |
|---|---|---|
| `image.registry` | `519915467343.dkr.ecr.us-east-1.amazonaws.com` | |
| `image.repository` | `""` | required; include the tag, e.g. `veyga/helloapp:1.2.3` |
| `deployment.command` | `[]` | entrypoint override |
| `deployment.httpPort` | `8080` | container port |
| `deployment.replicas` | `1` | |
| `deployment.env` | `{}` | extra env vars by name: `NAME: value`, or `NAME: {valueFrom: ...}`; merges across values files |
| `service.type` | `ClusterIP` | `ClusterIP`, `NodePort` or `LoadBalancer` |
| `service.port` | `80` | forwards to `deployment.httpPort` |
| `ingress.enabled` | `false` | |
| `ingress.className` | `traefik` | |
| `ingress.host` | `""` | required when the ingress is enabled |
| `ingress.clusterIssuer` | `clusterissuer-prod` | empty = no TLS |
| `environment` | `""` | container env `ENVIRONMENT` (e.g. `dev`, `prod`); empty = not set |
| `nodeSelector` | `{}` | |
