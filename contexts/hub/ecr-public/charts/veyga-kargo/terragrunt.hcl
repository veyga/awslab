# public OCI repository for the veyga-kargo helm chart (charts/), published by
# .github/workflows/charts.yml. The directory name must match the chart's Chart.yaml name.
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/ecr/public-repository"
}

inputs = {
  name        = "charts/${basename(get_terragrunt_dir())}"
  description = "veyga-kargo helm chart (veygawslab/awslab charts/)"
  tags        = include.root.locals.aws.tags
}
