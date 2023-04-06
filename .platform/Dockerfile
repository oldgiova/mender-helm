FROM gitlab.com/northern.tech/mender/dependency_proxy/containers/debian:bullseye-slim
LABEL REFRESHED_AT=20230302
# image used inside Gitlab CICD Pipelines

# Application list
ENV HELM_VERSION=v3.9.0
ENV KUBECTL_VERSION=1.22.15
ENV KUBECONFORM_VERSION=0.4.14
# env
ENV BIN_DIR /opt/buildbot/bin
ENV USER buildbot

# OS depenencies
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y \
       curl \
       wget \
       git \
       apt-transport-https \
       ca-certificates \
       gnupg \
       python3 \
       python3-pip \
       jq \
    && rm -rf /var/lib/apt/lists/*

# workdir
RUN useradd -ms /bin/bash ${USER} -d /opt/${USER}
RUN mkdir -p ${BIN_DIR}
WORKDIR ${BIN_DIR}

# kubectl
RUN curl -o ${BIN_DIR}/kubectl -L -s "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && KUBECTL_BIN="${BIN_DIR}/kubectl" \
    && chmod +x ${KUBECTL_BIN} \
    && curl -o ${BIN_DIR}/kubectl.sha256 -L -s "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256" \
    && echo "$(cat ${KUBECTL_BIN}.sha256) ${KUBECTL_BIN}" | sha256sum --check \
    && echo "INFO - kubectl version: " \
    && ${KUBECTL_BIN} version --client \
    && rm ${BIN_DIR}/kubectl.sha256 \
    && chown ${USER}. ${KUBECTL_BIN}
    
# helm
ENV HELM3_DOWNLOAD_URL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN curl -fsSL -o ${BIN_DIR}/get_helm.sh ${HELM3_DOWNLOAD_URL} \
    && chmod 700 ${BIN_DIR}/get_helm.sh \
    && DESIRED_VERSION=${HELM_VERSION} ${BIN_DIR}/get_helm.sh \
    # test it
    && HELM_BIN_TEMP=$(which helm) \
    && HELM_BIN=${BIN_DIR}/helm \
    && mv ${HELM_BIN_TEMP} ${HELM_BIN} \
    && ${HELM_BIN} version \
    && rm ${BIN_DIR}/get_helm.sh \
    && chown ${USER}. ${HELM_BIN}

# kubeconform install
RUN curl -fsSL -o /tmp/kubeconform.tar.gz https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz \
    && tar -xzf /tmp/kubeconform.tar.gz -C ${BIN_DIR} \
    && rm /tmp/kubeconform.tar.gz

#USER ${USER}
ENV PATH="${BIN_DIR}:${PATH}"

