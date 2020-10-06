#!/bin/bash

SHORT=r:i:t:h:n:u:p:
LONG=repository:,image:,tag:,host:,namespace:,user:,pw:

EXECUTE=$1
OPTS=$(getopt -o $SHORT --long $LONG --name "$2" -- "$@")

eval set -- "$OPTS"

# S: 변수 기본값 설정
REPOSITORY=docker.io
IMAGE=kimytsc/kakaopay-devops-assignment
TAG=2.1.0.BUILD-SNAPSHOT
HOST=petclinic.kakaopay.com
NAMESPACE=default
DOCKER_ID=
DOCKER_PW=
# E: 변수 기본값 설정

while true ; do
  case "$1" in
    -r | --repository ) REPOSITORY=$2; shift 2 ;;
    -i | --image ) IMAGE=$2; shift 2 ;;
    -t | --tag ) TAG=$2; shift 2 ;;
    -h | --host ) HOST=$2; shift 2 ;;
    -n | --namespace ) NAMESPACE=$2; shift 2 ;;
    -u | --user ) DOCKER_ID=$2; shift 2 ;;
    -p | --pw ) DOCKER_PW=$2; shift 2 ;;
    -- ) shift; break ;;
    *) break ;;
  esac
done

# echo "REPOSITORY: ${REPOSITORY}"
# echo "IMAGE: ${IMAGE}"
# echo "TAG: ${TAG}"
# echo "HOST: ${HOST}"
# echo "NAMESPACE: ${NAMESPACE}"
# echo "DOCKER_ID: ${DOCKER_ID}"
# echo "DOCKER_PW: ${DOCKER_PW}"
# echo 
# echo "EXECUTE: ${EXECUTE}"
# exit 0

build() {
  echo 
  echo "Application building..."
  echo 
  echo "Execute: ./gradlew build"
  echo 
  ./gradlew build
}

docker() {
  echo 
  echo "Application building..."
  echo 
  echo "Execute: ./gradlew docker -PdockerImage=\"${REPOSITORY}/${IMAGE}\" -Ptag=${TAG}"
  echo 
  ./gradlew docker -PdockerImage="${REPOSITORY}/${IMAGE}" -Ptag=${TAG}
}

dockerPush() {
  echo 
  echo "Execute: ./gradlew dockerPush -PdockerImage=\"${REPOSITORY}/${IMAGE}\" -Ptag=${TAG} -Pid=${DOCKER_ID} -Ppw=${DOCKER_PW}"
  echo 
  ./gradlew dockerPush -PdockerImage="${REPOSITORY}/${IMAGE}" -Ptag=${TAG} -Pid=${DOCKER_ID} -Ppw=${DOCKER_PW}
}

install() {
  echo
  echo "Database Service Installing..."
  echo
  echo "Execute: helm install petclinic.database ./helm/database/mysql --wait --set namespace=${NAMESPACE} --namespace=${NAMESPACE} --create-namespace"
  echo
  helm install petclinic.database ./helm/database/mysql --wait --debug --set namespace=${NAMESPACE} --namespace=${NAMESPACE} --create-namespace
  echo
  echo "Database Install OK!"

  echo
  echo "Application Service Installing..."
  echo
  echo "Execute: helm install petclinic.application ./helm/application/java --wait --set namespace=${NAMESPACE} --namespace=${NAMESPACE} --create-namespace --set image.repository=${REPOSITORY}/${IMAGE} --set image.tag=${TAG} --set ingress.hosts[0].host=${HOST} --set ingress.hosts[0].paths[0]=\"/\""
  echo
  helm install petclinic.application ./helm/application/java --wait --debug --set namespace=${NAMESPACE} --namespace=${NAMESPACE} --create-namespace --set image.repository=${REPOSITORY}/${IMAGE} --set image.tag=${TAG} --set ingress.hosts[0].host=${HOST} --set ingress.hosts[0].paths[0]="/"
  echo
  echo "Application Install OK!"
}

upgrade() {
  echo
  echo "Database Service Upgrading..."
  echo
  echo "Execute: helm upgrade petclinic.database ./helm/database/mysql --wait --install --set namespace=${NAMESPACE}"
  echo
  helm upgrade petclinic.database ./helm/database/mysql --wait --install --set namespace=${NAMESPACE}
  echo
  echo "Database Upgrade OK!"

  echo
  echo "Application Service Upgrading..."
  echo
  echo "Execute: helm upgrade petclinic.application ./helm/application/java --wait --install --set namespace=${NAMESPACE} --set image.repository=${REPOSITORY}/${IMAGE} --set image.tag=${TAG} --set ingress.hosts[0].host=${HOST} --set ingress.hosts[0].paths[0]=\"/\""
  echo
  helm upgrade petclinic.application ./helm/application/java --wait --install --set namespace=${NAMESPACE} --set image.repository=${REPOSITORY}/${IMAGE} --set image.tag=${TAG} --set ingress.hosts[0].host=${HOST} --set ingress.hosts[0].paths[0]="/"
  echo
  echo "Application Upgrade OK!"
}

delete() {
  echo
  echo "Database, Application Service Stopping..."
  echo
  echo "Execute: helm delete petclinic.database --namespace=${NAMESPACE}"
  echo
  helm delete petclinic.database --namespace=${NAMESPACE}
  echo
  echo "Execute: helm delete petclinic.application --namespace=${NAMESPACE}"
  echo
  helm delete petclinic.application --namespace=${NAMESPACE}
  # sleep 30
  echo
  echo "Application, Database Delete OK!"
}

status() {
  echo 
  kubectl -n ${NAMESPACE} get pods,services,configmaps,deployments,ingress,persistentvolumes,persistentvolumeclaims --show-labels --show-kind
  echo 
}

deploy() {
  dockerPush
  if [[ `kubectl get namespace | awk -v OFS='\t' '{print $1}' | grep ${NAMESPACE} | wc -l` -eq 0 ]]; then
    install
  else
    upgrade
  fi
}

case "${EXECUTE}" in
  build) build ;;
  docker) docker ;;
  dockerPush) dockerPush ;;
  install) install ;;
  upgrade) upgrade ;;
  delete) delete ;;
  status) status ;;
  deploy) deploy ;;
  *) echo "Usage: $0 {build | docker | dockerPush | install | upgrade | delete | status | deploy} [--option]" ;;
esac
exit 0
