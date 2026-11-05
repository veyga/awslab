{{/* Kargo Project name, which is also the namespace its Warehouse/Stages live in */}}
{{- define "veygaKargo.project" -}}
kargo-{{ .Values.name }}
{{- end -}}

{{/* Warehouse name for a type (dev | prod) */}}
{{- define "veygaKargo.warehouse" -}}
{{ .context.Values.name }}-{{ .type }}
{{- end -}}

{{/* Warehouse types in use: prod always, dev when a stage uses it (JSON list) */}}
{{- define "veygaKargo.warehouseTypes" -}}
{{- $types := list "prod" -}}
{{- range .Values.stages -}}
{{- if eq .warehouse "dev" -}}{{- $types = list "dev" "prod" -}}{{- end -}}
{{- end -}}
{{- $types | toJson -}}
{{- end -}}

{{/* Argo CD Application name for a stage */}}
{{- define "veygaKargo.appName" -}}
{{ .context.Values.name }}-{{ .stage.name }}
{{- end -}}

{{/* Where a stage's rendered manifests live in the gitops repo: <stage>/<name> */}}
{{- define "veygaKargo.gitopsPath" -}}
{{ .stage.name }}/{{ .context.Values.name }}
{{- end -}}

{{/* Namespace a stage's app is rendered into and deployed to */}}
{{- define "veygaKargo.namespace" -}}
{{ .stage.namespace | default (printf "%s-%s" .context.Values.name .stage.name) }}
{{- end -}}

{{- define "veygaKargo.labels" -}}
app.kubernetes.io/name: {{ .Values.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{/* Argo CD sync wave: the Project (and its namespace) must exist before the rest */}}
{{- define "veygaKargo.wave" -}}
argocd.argoproj.io/sync-wave: {{ . | quote }}
{{- end -}}

{{/* A Kargo expression, ${{ ... }}, emitted verbatim (Helm doesn't interpret it) */}}
{{- define "veygaKargo.expr" -}}
{{- printf "${{ %s }}" . -}}
{{- end -}}

{{/* Stage color in the Kargo UI, cycling through a fixed palette */}}
{{- define "veygaKargo.color" -}}
{{- $colors := list "#3B82F6" "#10B981" "#F59E0B" "#8B5CF6" "#EC4899" "#06B6D4" "#F97316" "#14B8A6" -}}
{{- index $colors (mod . (len $colors)) -}}
{{- end -}}

{{/* Fail on what the schema can't express: duplicate stages, unknown upstreams, no entry stage */}}
{{- define "veygaKargo.validate" -}}
{{- $names := dict -}}
{{- $entry := false -}}
{{- range .Values.stages -}}
{{- if hasKey $names .name -}}
{{- fail (printf "stage %q is defined twice" .name) -}}
{{- end -}}
{{- $_ := set $names .name true -}}
{{- if not .upstream -}}{{- $entry = true -}}{{- end -}}
{{- end -}}
{{- range $stage := .Values.stages -}}
{{- range $stage.upstream -}}
{{- if not (hasKey $names .) -}}
{{- fail (printf "stage %q has upstream %q, which is not a stage" $stage.name .) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if not $entry -}}
{{- fail "at least one stage needs an empty upstream (it takes freight straight from the Warehouse)" -}}
{{- end -}}
{{- end -}}

{{/*
Promotion steps for one stage: clone the app repo at the freight's commit (./src) and the
gitops branch (./out), replace out/<stage>/<name> with the chart rendered from src (image
tags pinned from the freight), commit, then either push to the gitops branch (direct-push)
or PR into it and wait for the merge (git-pr), and finally sync the stage's Argo CD app.
Only the stage's own directory is replaced: git-clear would wipe the whole gitops repo.
Usage: include "veygaKargo.steps" (dict "stage" $stage "context" $)
*/}}
{{- define "veygaKargo.steps" -}}
{{- $ctx := .context -}}
{{- $stage := .stage -}}
{{- $src := $ctx.Values.gitRepo -}}
{{- $gitops := $ctx.Values.gitops.repoURL -}}
{{- $branch := $ctx.Values.gitops.branch -}}
{{- $app := include "veygaKargo.appName" . -}}
{{- $dir := printf "./out/%s" (include "veygaKargo.gitopsPath" .) -}}
{{- $origin := "warehouse(ctx.targetFreight.origin.name)" -}}
{{- $changed := "outputs.commit.commit != outputs.cloneOut.commits.out" -}}
{{- $message := printf "'kargo: promote %s to %s (freight ' + ctx.targetFreight.name + ')'" $ctx.Values.name $stage.name -}}
- uses: git-clone
  as: cloneSrc
  config:
    repoURL: {{ $src }}
    checkout:
      - commit: {{ include "veygaKargo.expr" (printf "commitFrom('%s', %s).ID" $src $origin) | quote }}
        path: ./src
- uses: git-clone
  as: cloneOut
  config:
    repoURL: {{ $gitops }}
    checkout:
      - branch: {{ $branch }}
        path: ./out
        as: out
- uses: delete
  config:
    path: {{ $dir }}
- uses: helm-template
  config:
    path: ./src/{{ $ctx.Values.render.chartPath }}
    releaseName: {{ $ctx.Values.render.releaseName | default $ctx.Values.name }}
    namespace: {{ include "veygaKargo.namespace" . }}
    buildDependencies: {{ $ctx.Values.render.buildDependencies }}
    includeCRDs: {{ $ctx.Values.render.includeCRDs }}
    valuesFiles:
    {{- range $stage.valuesFiles }}
      - ./src/{{ . }}
    {{- end }}
    {{- if or $ctx.Values.images $ctx.Values.render.environmentValueKey }}
    setValues:
    {{- range $ctx.Values.images }}
      - key: {{ .helmValueKey }}
        value: {{ include "veygaKargo.expr" (printf "'%s' + imageFrom('%s', %s).Tag" (.helmValuePrefix | default "") .repoURL $origin) | quote }}
    {{- end }}
    {{- with $ctx.Values.render.environmentValueKey }}
      - key: {{ . }}
        value: {{ $stage.name | quote }}
    {{- end }}
    {{- end }}
    outLayout: flat
    outPath: {{ $dir }}
- uses: git-commit
  as: commit
  config:
    path: ./out
    message: {{ include "veygaKargo.expr" $message | quote }}
{{- if eq ($stage.promotion | default "direct-push") "git-pr" }}
- uses: git-push
  as: push
  if: {{ include "veygaKargo.expr" $changed | quote }}
  config:
    path: ./out
    generateTargetBranch: true
- uses: git-open-pr
  as: pr
  if: {{ include "veygaKargo.expr" $changed | quote }}
  config:
    repoURL: {{ $gitops }}
    sourceBranch: {{ include "veygaKargo.expr" "outputs.push.branch" | quote }}
    targetBranch: {{ $branch }}
    title: {{ include "veygaKargo.expr" $message | quote }}
- uses: git-wait-for-pr
  if: {{ include "veygaKargo.expr" $changed | quote }}
  config:
    repoURL: {{ $gitops }}
    prNumber: {{ include "veygaKargo.expr" "outputs.pr.pr.id" | quote }}
- uses: argocd-update
  config:
    apps:
      - name: {{ $app }}
        namespace: {{ $ctx.Values.argocd.namespace }}
        sources:
          - repoURL: {{ $gitops }}
{{- else }}
- uses: git-push
  config:
    path: ./out
- uses: argocd-update
  config:
    apps:
      - name: {{ $app }}
        namespace: {{ $ctx.Values.argocd.namespace }}
        sources:
          - repoURL: {{ $gitops }}
            desiredRevision: {{ include "veygaKargo.expr" "outputs.commit.commit" | quote }}
{{- end }}
{{- end -}}
