CHART_REPO := http://jenkins-x-chartmuseum:8080
NAME := nexus
OS := $(shell uname)

CHARTMUSEUM_CREDS_USR := $(shell cat /builder/home/basic-auth-user.json)
CHARTMUSEUM_CREDS_PSW := $(shell cat /builder/home/basic-auth-pass.json)

init:
	helm init --client-only

setup: init
	helm repo add jenkins-x http://chartmuseum.jenkins-x.io 	

build: clean setup
	helm dependency build nexus
	helm lint nexus

install: clean build
	helm upgrade ${NAME} nexus --install

upgrade: clean build
	helm upgrade ${NAME} nexus --install

delete:
	helm delete --purge ${NAME} nexus

clean:
	rm -rf nexus/charts
	rm -rf nexus/${NAME}*.tgz
	rm -rf nexus/requirements.lock

release: clean build
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(VERSION)/" nexus/Chart.yaml

else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(VERSION)/" nexus/Chart.yaml
else
	exit -1
endif
	helm package nexus
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(VERSION).tgz" $(CHART_REPO)/api/charts
	rm -rf ${NAME}*.tgz
