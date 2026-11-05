# argocd/root

Synced by Argo CD's root Application (Terraform: `contexts/hub/k8s/argocd/root`). Everything
Argo CD deploys starts here:

| File | |
|---|---|
| `<app>.yaml` | one per app (project `default`): installs its Kargo pipeline from the app repo's `deploy/kargo` |

The pipeline then creates the app's per-stage Applications, which deploy what Kargo renders
into [veygawslab/gitops](https://github.com/veygawslab/gitops) at `<stage>/<app>/`.
