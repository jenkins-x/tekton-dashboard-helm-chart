NAME := tekton-dashboard
CHART_DIR := charts/${NAME}
CHART_VERSION ?= latest
RESOURCE_YAML := ${CHART_DIR}/templates/resource.yaml

CHART_REPO := gs://jenkinsxio/charts

prep:
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
  # Remove namespace from metadata to force with helm install
	find $(CHART_DIR)/templates -type f -name "*.yaml" -exec yq -i eval 'del(.metadata.namespace)' "{}" \;
  # Amend subjects.namespace with release.namespace
	find . -type f \( -name "*-crb.yaml" -o -name "*-rb.yaml" \)  -exec yq -i '(.subjects[] | select(has("namespace"))).namespace = "{{ .Release.Namespace }}"' "{}" \;
  # Add dynamic external-logs container arg
	yq  '.spec.template.spec.containers[0].args[]  | split("=") | [.[0] | sub("^--","") , .[1] ] as $$item ireduce({}; .[$$item[0]] = $$item[1])' $(CHART_DIR)/templates/tekton-dashboard-deploy.yaml > args.yaml
	yq -i '.args = load("args.yaml")' $(CHART_DIR)/values.yaml
  # kustomize the resources to include some helm template blocs
	kustomize build ${CHART_DIR} | sed '/helmTemplateRemoveMe/d' > ${CHART_DIR}/templates/resource.yaml
	jx gitops split -d ${CHART_DIR}/templates
	jx gitops rename -d ${CHART_DIR}/templates
  # Remove temporary files
	rm -f ${RESOURCE_YAML} args.yaml
  # Copy src templates
	cp src/templates/* ${CHART_DIR}/templates

fetch: prep
  # Set value in Chart.yaml
	yq eval -i '.appVersion = "$(shell yq eval '.data.version | sub("v"; "")' ${CHART_DIR}/templates/dashboard-info-cm.yaml)"' ${CHART_DIR}/Chart.yaml

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
