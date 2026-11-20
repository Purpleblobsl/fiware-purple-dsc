{{/*
Expand the name of the chart.
*/}}
{{- define "purple-dsc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "purple-dsc.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "purple-dsc.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "purple-dsc.labels" -}}
helm.sh/chart: {{ include "purple-dsc.chart" . }}
{{ include "purple-dsc.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "purple-dsc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "purple-dsc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "purple-dsc.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "purple-dsc.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account used by generated jobs.
*/}}
{{- define "purple-dsc.jobServiceAccountName" -}}
{{- if .Values.jobs.serviceAccount.create }}
{{- default (printf "%s-jobs" (include "purple-dsc.fullname" .)) .Values.jobs.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.jobs.serviceAccount.name }}
{{- end }}
{{- end }}
