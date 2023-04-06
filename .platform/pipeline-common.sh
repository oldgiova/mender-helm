#!/bin/bash

# Pipeline common functions

function validate_helm() {
  for KUBERNETES_VERSION in "1.22" "1.23" "1.24" "1.25"; do
    echo "INFO - testing helm chart over kubernetes version ${KUBERNETES_VERSION}"
    helm template \
      -f test/values.yaml \
      mender \
      | kubeconform \
          -summary \
          -kubernetes-version ${KUBERNETES_VERSION} \
          -verbose
  done
}

function version_bump() {
  # check if pipeline is triggered remotely, if so the FRONTEND_MVN_VERSION has value
  REMOTE_PROJECT_NAME=${1:-deployments}

  pip install -r .platform/requirements.txt

  python3 .platform/set_gitops_new_values.py ${YAML_FILE} ${BACKEND_MVN_VERSION}
  #verify it
  echo "INFO - new mender2 backend tag on Chart.yaml is: "
  grep 'appVersion:' ${YAML_FILE} | grep ${BACKEND_MVN_VERSION}
  if [[ $? -ne 0 ]]; then
    echo "ERROR - helm values not updated, check errors"
    exit 1
  fi

  if [[ "${FRONTEND_MVN_VERSION}" != "nope" ]]; then
    python3 .devops/set_gitops_new_values_frontend.py charts/mender2/values-${mender_ENV}.yaml  ${FRONTEND_MVN_VERSION}
    #verify it
    echo "INFO - new mender2 Frontend tag on values-prod.yaml is: "
    grep 'tag:' charts/mender2/values-${mender_ENV}.yaml | grep ${FRONTEND_MVN_VERSION}
    if [[ $? -ne 0 ]]; then
      echo "ERROR - helm frontend values not updated, check errors"
      exit 1
    fi
  else
    echo "INFO - no new mender2 Frontend release. Skipping"
  fi
}

function git_push_back() {
  CHANGED_FILE=$@
  FILE_IS_CHANGED=0
  git diff --exit-code ${CHANGED_FILE} || FILE_IS_CHANGED=1
  if [[ ${FILE_IS_CHANGED} -eq 1 ]]; then
    echo "INFO - pushing back ${CHANGED_FILE}"
    git config user.email "builder@memooria.org"
    git config user.name "Builder Bot"
    git add ${CHANGED_FILE}
    git commit -m "[builder] bump Chart.yaml version"
    git remote rm builder || echo "INFO - git remote builder not exists"
    git remote add builder ${BUILDERBOT_TOKEN_URL}
    git push -o ci.skip builder HEAD:$CI_COMMIT_BRANCH
  else
    echo "INFO - nevermind, nothing to commit"
  fi
}

function update_versionmd() {
  CURRENT_ENV=${1:-qa}
  CHART_VERSION=$(cat charts/mender2/Chart.yaml | grep version | awk '{print $2}')
  BACKEND_VERSION=$(cat charts/mender2/Chart.yaml | grep appVersion | awk '{print $2}')
  FRONTEND_VERSION=$(cat charts/mender2/values-${CURRENT_ENV}.yaml | grep frontend: -A2 | grep tag: | awk '{print $2}' | tr -d \')

  # writing mender2_VERSION.md
  echo "# Current mender2 version for this branch:" > mender2_VERSION.md
  echo "" >> mender2_VERSION.md
  echo "* chart version: ${CHART_VERSION}" >> mender2_VERSION.md
  echo "* backend version: ${BACKEND_VERSION}" >> mender2_VERSION.md
  echo "* frontend version: ${FRONTEND_VERSION}" >> mender2_VERSION.md
}
