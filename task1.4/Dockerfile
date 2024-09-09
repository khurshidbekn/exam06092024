FROM ubuntu:22.04

RUN apk add --no-cache curl bash

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

RUN mkdir -p /root/.kube

COPY p-xurshid-config /root/.kube/config

ENV KUBECONFIG=/root/.kube/config

CMD ["sh"]

