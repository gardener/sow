FROM alpine:3.9

RUN apk update && apk add --no-cache bash curl libc6-compat
RUN apk add git
RUN apk add terraform
RUN apk add jq
RUN curl -L -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.13.3/bin/linux/amd64/kubectl
RUN curl -L -o helm-archive.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-v2.13.0-rc.2-linux-amd64.tar.gz \
    && mkdir helm-extract \
    && tar -xzf helm-archive.tar.gz -C helm-extract \
    && cp helm-extract/linux-amd64/helm /usr/bin/helm \
    && rm -rf helm-archive.tar.gz helm-extract
RUN curl -L -o spiff-archive.zip https://github.com/mandelsoft/spiff/releases/download/v1.3.0-beta-2/spiff_linux_amd64.zip \
    && mkdir spiff-extract \
    && unzip -d spiff-extract spiff-archive.zip \
    && cp "spiff-extract/spiff++" /usr/bin/spiff \
    && rm -rf spiff-archive.zip spiff-extract
RUN git clone https://github.com/mandelsoft/sow.git
RUN chmod +x /usr/bin/*
ENV PATH=$PATH:$PWD/sow/bin
ENTRYPOINT ["sow"]