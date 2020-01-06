CHART_REPO := http://jenkins-x-chartmuseum:8080
NAME := nexus
OS := $(shell uname)

init:
	helm init --client-only

setup: init
	helm repo add jenkinsxio http://chartmuseum.jenkins-x.io

build: clean setup
	helm dependency build charts/nexus
	helm lint charts/nexus

install: clean build
	helm install charts/nexus --name ${NAME}
	watch kubectl get pods

upgrade: clean build
	helm upgrade ${NAME} charts/nexus
	watch kubectl get pods

delete:
	helm delete --purge ${NAME}

clean:
	rm -rf charts/neuxs/charts
	rm -rf charts/nexus/${NAME}*.tgz
	rm -rf charts/nexus/requirements.lock

release: clean build
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(VERSION)/" charts/nexus/Chart.yaml
	sed -i "" -e "s/tag:.*/tag: $(VERSION)/" charts/nexus/values.yaml
else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(VERSION)/" charts/nexus/Chart.yaml
	sed -i "" -e "s/tag:.*/tag: $(VERSION)/" charts/nexus/values.yaml
else
	exit -1
endif
	helm package charts/nexus
	curl --fail -u $(CHARTMUSEUM_USER):$(CHARTMUSEUM_PASS) --data-binary "@charts/nexus/$(NAME)-$(VERSION).tgz" $(CHART_REPO)/api/charts
	rm -rf charts/nexus/${NAME}*.tgz

delete-from-chartmuseum:
	curl --fail -u $(CHARTMUSEUM_USER):$(CHARTMUSEUM_PASS) -X DELETE $(CHART_REPO)/api/charts/$(NAME)/$(VERSION)
