{{/*
Returns the appropriate apiVersion for podDisruptionBudget object.
*/}}
{{- define "capabilities.podDisruptionBudget.apiVersion" -}}
{{- if semverCompare ">=1.21-0" ( .Values.kubeVersion | default .Capabilities.KubeVersion.Version ) -}}
{{- print "policy/v1" -}}
{{- else -}}
{{- print "policy/v1beta1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for HorizontalPodAutoscaler object.
*/}}
{{- define "capabilities.horizontalPodAutoscaler.apiVersion" -}}
{{- if semverCompare "<1.23-0" ( .Values.kubeVersion | default .Capabilities.KubeVersion.Version ) -}}
{{- print "autoscaling/v2beta2" -}}
{{- else -}}
{{- print "autoscaling/v2" -}}
{{- end -}}
{{- end -}}
