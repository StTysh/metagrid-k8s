{{/*
Expand the name of the chart.
*/}}
{{- define "metagrid.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "metagrid.fullname" -}}
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
{{- define "metagrid.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{/*
Common labels
*/}}
{{- define "metagrid.labels" -}}
helm.sh/chart: {{ include "metagrid.chart" . }}
{{ include "metagrid.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
{{/*
Selector labels
*/}}
{{- define "metagrid.selectorLabels" -}}
app.kubernetes.io/name: {{ include "metagrid.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{/*
Postgres host
*/}}
{{- define "metagrid.pg_host" -}}
{{- if .Values.postgresql.enabled }}
{{ include "postgresql-ha.pgpool" .Subcharts.postgresql }}
{{- else }}
{{- .Values.ownpgserver.host }}
{{- end }}
{{- end }}
{{/*
Postgres port
*/}}
{{- define "metagrid.pg_port" -}}
{{- if .Values.postgresql.enabled }}
{{ .Subcharts.postgresql.Values.service.ports.postgresql }}
{{- else }}
{{- .Values.ownpgserver.port }}
{{- end }}
{{- end }}
{{/*
Postgres db
*/}}
{{- define "metagrid.pg_db" -}}
{{- if .Values.postgresql.enabled }}
{{ include "postgresql-ha.postgresqlDatabase" .Subcharts.postgresql }}
{{- else }}
{{- .Values.ownpgserver.database }}
{{- end }}
{{- end }}
{{/*
Postgres user
*/}}
{{- define "metagrid.pg_user" -}}
{{- if .Values.postgresql.enabled }}
{{ include "postgresql-ha.postgresqlUsername" .Subcharts.postgresql }}
{{- else }}
{{- .Values.ownpgserver.username }}
{{- end }}
{{- end }}
{{/*
Postgres pass
*/}}
{{- define "metagrid.pg_pass" -}}
{{- if .Values.postgresql.enabled }}
{{ include "postgresql-ha.postgresqlPassword" .Subcharts.postgresql }}
{{- else }}
{{- .Values.ownpgserver.password }}
{{- end }}
{{- end }}
{{/*
Postgres URI
*/}}
{{- define "metagrid.pg_uri" -}}
{{- if .Values.postgresql.enabled }}
postgres://{{ include "metagrid.pg_user" $ }}:{{ include "metagrid.pg_pass" $ }}@{{ include "metagrid.pg_host" $ }}:{{ include "metagrid.pg_port" $ }}/{{ include "metagrid.pg_db" $ }}
{{- end }}
{{- end }}
{{/*
React base url
*/}}
{{- define "metagrid.react.baseUrl" -}}
{{- $host := ternary .Values.ingress.react.host (printf "127.0.0.1:%v" .Values.react.service.port) .Values.ingress.enabled }}
{{- $scheme := ternary "https" "http" (and .Values.ingress.enabled .Values.ingress.tls.enabled) }}
{{- printf "%s" (default (printf "%s://%s" $scheme $host) .Values.baseUrl) }}
{{- end }}
{{/*
React Url
*/}}
{{- define "metagrid.react.url" -}}
{{- $baseUrl := include "metagrid.react.baseUrl" . }}
{{- printf "%s%s" $baseUrl (printf "/%s" (trimPrefix "/" .Values.react.urlPath)) }}
{{- end }}
{{/*
Django base url
*/}}
{{- define "metagrid.django.baseUrl" -}}
{{- $host := ternary .Values.ingress.django.host (printf "127.0.0.1:%v" .Values.django.service.port) .Values.ingress.enabled }}
{{- $scheme := ternary "https" "http" (and .Values.ingress.enabled .Values.ingress.tls.enabled) }}
{{- printf "%s" (default (printf "%s://%s" $scheme $host) .Values.baseUrl) }}
{{- end }}
{{/*
Django Url
*/}}
{{- define "metagrid.django.url" -}}
{{- $baseUrl := include "metagrid.django.baseUrl" . }}
{{- printf "%s%s" $baseUrl (printf "/%s" (trimPrefix "/" .Values.django.urlPath)) }}
{{- end }}
{{/*
Django login url
*/}}
{{- define "metagrid.django.loginUrl" -}}
{{- $baseUrl := include "metagrid.django.url" . }}
{{- printf "%s/login/globus/" $baseUrl }}
{{- end }}
{{/*
Django logout url
*/}}
{{- define "metagrid.django.logoutUrl" -}}
{{- $baseUrl := include "metagrid.django.url" . }}
{{- printf "%s/proxy/globus-logout/" $baseUrl }}
{{- end }}
{{/*
Django login redirect
*/}}
{{- define "metagrid.django.loginRedirect" -}}
{{- $baseUrl := include "metagrid.react.url" . }}
{{- printf "%s/%s" $baseUrl (trimPrefix "/" .Values.django.loginRedirect) }}
{{- end }}
{{/*
Django logout redirect
*/}}
{{- define "metagrid.django.logoutRedirect" -}}
{{- $baseUrl := include "metagrid.react.url" . }}
{{- printf "%s/%s" $baseUrl (trimPrefix "/" .Values.django.logoutRedirect) }}
{{- end }}
{{/*
Django ALLOWED_HOSTS
*/}}
{{- define "metagrid.djangoAllowedHosts" -}}
{{- join "," (list "127.0.0.1" "localhost" (printf "%s-django" (include "metagrid.fullname" .)) .Values.ingress.react.host ) -}}
{{- end }}
{{/*
Django CORS_ORIGIN_WHITELIST
*/}}
{{- define "metagrid.django.corsOriginWhitelist" -}}
{{- printf "%s" (include "metagrid.react.baseUrl" .) }}
{{- end }}
{{- define "metagrid.podSpec" -}}
{{- with .affinity }}
affinity:
{{- toYaml . | nindent 2 }}
{{- end -}}
containers:
- name: {{ .name }}
  {{- with .args }}
  args:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .command }}
  command:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .env }}
  env:
  {{- range $name, $value := . }}
  - name: {{ $name }}
    value: {{ tpl $value $.TemplateValues | quote }}
  {{- end }}
  {{- end }}
  {{- with .envFrom }}
  envFrom:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  image: {{ .image.repository }}:{{ .image.tag }}
  {{- with .image.pullPolicy }}
  imagePullPolicy: {{ . }}
  {{- end }}
  {{- with .livenessProbe }}
  livenessProbe:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .service }}
  ports:
  - name: {{ .name }}
    containerPort: {{ .port }}
    protocol: {{ default "TCP" .protocol }}
  {{- end }}
  {{- with .readinessProbe }}
  readinessProbe:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .resources }}
  resources:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .securityContext }}
  securityContext:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .startupProbe }}
  startupProbe:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .persistence }}
  volumeMounts:
  - mountPath: {{ .mountPath }}
    name: {{ .name }}
    readOnly: {{ default "false" .readOnly }}
    {{- with .subPath }}
    subPath: {{ . }}
    {{- end }}
  {{- end }}
{{- with .dnsConfig }}
dnsConfig:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .dnsPolicy }}
dnsPolicy: {{ . }}
{{- end }}
{{- with .image.pullSecrets }}
imagePullSecrets:
- name: {{ include "metagrid.fullname" .TemplateValues }}
{{- end }}
{{- with .nodeSelector }}
nodeSelector:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .preemptionPolicy }}
preemptionPolicy: {{ . }}
{{- end }}
{{- with .priority }}
priority: {{ . }}
{{- end }}
{{- with .priorityClassName }}
priorityClassName: {{ . }}
{{- end }}
{{- with .restartPolicy }} 
restartPolicy: {{ . }}
{{- end }}
{{- with .runtimeClassName }}
runtimeClassName: {{ . }}
{{- end }}
{{- with .podSecurityContext }}
securityContext:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .tolerations }}
tolerations:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .persistence }}
volumes:
{{- if eq .type "configmap" }}
- configMap:
    name: {{ .resourceName }}
{{- else if eq .type "secret" }}
- secret:
    secretName: {{ .resourceName }}
{{- else if eq .type "emptyDir" }}
- emptyDir: {}    
{{- end }}
  name: {{ .name }}
{{- end }}
{{- end }}