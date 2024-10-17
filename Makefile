NAME := tekton-dashboard
CHART_DIR := charts/${NAME}
CHART_VERSION ?= latest
RESOURCE_YAML := ${CHART_DIR}/templates/resource.yaml

CHART_REPO := gs://jenkinsxio/charts

fetch:
	rm -f ${CHART_DIR}/templates/*.yaml
	mkdir -p ${CHART_DIR}/templates
ifeq ($(CHART_VERSION),latest)
	curl -sS https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml > ${RESOURCE_YAML}
else
	curl -sS https://storage.googleapis.com/tekton-releases/dashboard/previous/v${CHART_VERSION}/release.yaml > ${RESOURCE_YAML}
endif
  # Split and rename resource.yaml
	jx gitops split -d ${CHART_DIR}/templates
	jx gitops rename -d ${CHART_DIR}/templates
  # kustomize the resources to include some helm template blocs
	kustomize build ${CHART_DIR} | sed '/helmTemplateRemoveMe/d' > ${RESOURCE_YAML}
  # Remove namespace from metadata to force with helm install
	find $(CHART_DIR)/templates -type f -name "*.yaml" -exec yq -i eval 'del(.metadata.namespace)' "{}" \;
  # Amend subjects.namespace with release.namespace
	find . -type f \( -name "*-crb.yaml" -o -name "*-rb.yaml" \)  -exec yq -i '(.subjects[] | select(has("namespace"))).namespace = "{{ .Release.Namespace }}"' "{}" \;
  # Add dynamic external-logs container arg
	yq -i '(.spec.template.spec.containers[].args[] | select(. == "--external-logs=")) = "--external-logs={{ .Values.container.externalLogs | default \"\" }}"' ${CHART_DIR}/templates/tekton-dashboard-deploy.yaml
  # Clean up divider chars
	sed -i '/---/d' ${CHART_DIR}/templates/*
  # Remove resource.yaml
	rm -f ${RESOURCE_YAML}
  # Copy src templates
	cp src/templates/* ${CHART_DIR}/templates
ifneq ($(CHART_VERSION),latest)
	sed -i "s/^appVersion:.*/appVersion: ${CHART_VERSION}/" ${CHART_DIR}/Chart.yaml
endif

build:
	rm -rf Chart.lock
	#helm dependency build
	helm lint ${NAME}

install: clean build
	helm install . --name ${NAME}

upgrade: clean build
	helm upgrade ${NAME} .

delete:
	helm delete --purge ${NAME}

clean:

release: clean
	sed -i -e "s/version:.*/version: $(VERSION)/" Chart.yaml

	helm dependency build
	helm lint
	helm package .
	helm repo add jx-labs $(CHART_REPO)
	helm gcs push ${NAME}*.tgz jx-labs --public
	rm -rf ${NAME}*.tgz%

test:
	cd tests && go test -v

test-regen:
	cd tests && export HELM_UNIT_REGENERATE_EXPECTED=true && go test -v


verify:
	jx kube test run
