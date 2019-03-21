CHART_REPO := http://jenkins-x-chartmuseum:8080
NAME := nexus
OS := $(shell uname)

CHARTMUSEUM_CREDS_USR := $(shell cat /builder/home/basic-auth-user.json)
CHARTMUSEUM_CREDS_PSW := $(shell cat /builder/home/basic-auth-pass.json)

build: clean
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
	rm -rf charts/nexus/charts
	rm -rf charts/nexus/${NAME}*.tgz
	rm -rf charts/nexus/requirements.lock

release: clean build
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(VERSION)/" charts/nexus/Chart.yaml
	sed -i "" -e "s/tag:.*/tag: $(VERSION)/" charts/nexus/values.yaml

else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(VERSION)/" charts/nexus/Chart.yaml
	sed -i -e "s/tag:.*/tag: $(VERSION)/" charts/nexus/values.yaml
else
	exit -1
endif
	helm package charts/nexus
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(VERSION).tgz" $(CHART_REPO)/api/charts
	rm -rf ${NAME}*.tgz