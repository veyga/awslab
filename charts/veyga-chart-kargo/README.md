# veyga-kargo

One app's Kargo pipeline on the single `hub` cluster. The app's own repo holds its chart
(`render.chartPath`, e.g. `deploy/`); Kargo renders it per stage into the shared gitops repo
at `<stage>/<name>/`. Apps depend on this chart from their own `deploy/kargo` chart, and
their `deploy/application.yaml` ApplicationSet (synced by Argo CD's root Application, awslab
`contexts/hub/k8s/argocd/root`) installs it and creates the per-stage Applications
`<name>-<stage>` that deploy `<stage>/<name>/` (annotated
`kargo.akuity.io/authorized-stage: kargo-<name>:<stage>`).

| Resource | Name | |
|---|---|---|
| Project | `kargo-<name>` | also the namespace the rest lives in |
| Warehouse | `<name>-prod` | release freight: CalVer (`YYYY.M.N`) image tags, cut on merge to main. Always created |
| Warehouse | `<name>-dev` | build freight: short-sha image tags (from PRs), newest build. When a stage uses it |
| Stage (per stage) | `<stage>` | renders the app's chart into gitops `<stage>/<name>/` |
| ProjectConfig | `kargo-<name>` | only when a stage sets `autoPromotion: true` |

Freight = an image tag per `images[]` plus the newest app-repo commit touching
`render.chartPath`. A `warehouse: dev` stage takes freight from both Warehouses, so a release
can be verified there before a `warehouse: prod` stage (release freight only) gets it.

## Promotion

Each Stage clones the app repo at the freight's commit and the gitops branch, replaces
`<stage>/<name>/` with `helm template` of `render.chartPath` (the stage's `valuesFiles`, each
image tag pinned into its `helmValueKey`, and the stage name into
`render.environmentValueKey`), commits, then syncs `<name>-<stage>`:

- `direct-push` (default): pushes straight to the gitops branch.
- `git-pr`: opens a PR into the gitops branch and waits for it to be merged. The git token
  needs "Pull requests: read and write" on the gitops repo for this.

Kargo needs git read on the app repo and read/write on the gitops repo (shared credentials in
the `kargo` namespace), and ECR read for images and chart dependencies (controller pod
identity). No per-project RBAC: anyone who can log in to Kargo can promote.

## Values

```yaml
name: exampleapp
gitRepo: https://github.com/veygawslab/exampleapp.git
render:
  environmentValueKey: veyga-microservice.environment # ENVIRONMENT=<stage>
images:
  - repoURL: 519915467343.dkr.ecr.us-east-1.amazonaws.com/veyga/exampleapp
    helmValueKey: veyga-microservice.image.repository
    helmValuePrefix: "veyga/exampleapp:"               # value written = prefix + tag
stages:
  - name: dev
    warehouse: dev                                     # PR builds + releases
    valuesFiles: [deploy/manifests/bases/common/values.yaml, deploy/manifests/overlays/dev/values.yaml]
  - name: prod
    warehouse: prod                                    # releases only, once verified in dev
    upstream: [dev]
    valuesFiles: [deploy/manifests/bases/common/values.yaml, deploy/manifests/overlays/prod/values.yaml]
```

Everything else has defaults (`values.yaml`); unknown keys are rejected by `values.schema.json`.
