FROM node:8.17.0-alpine

ARG SPACY_VERSION
ARG SPACY_MODEL

ENV PORT 3000
ENV SPACY_LOG_LEVEL error

COPY ./entry/.bashrc /root/.bashrc

RUN apk update && apk add --no-cache python3 tini bash libgomp && \
    apk add --no-cache --virtual .build-deps \
        build-base \
        subversion \
        python3-dev \
        g++ && \

    ln -s /usr/bin/python3 /usr/bin/python && \

    python3 -m ensurepip && \
    pip3 install --upgrade pip setuptools && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \

    python3 -m pip install -U socketIO-client-nexus spacy==${SPACY_VERSION} && \
    python3 -m spacy download ${SPACY_MODEL} && \
    pip show spacy > /etc/spacy_info && \

    apk del .build-deps \
        build-base \
        subversion \
        python3-dev \
        g++ && \

    rm -r /usr/lib/python*/ensurepip

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY src/package*.json ./

# The git package is required if we reference a GitHub repository in package.json
RUN npm install --loglevel=warn pm2 -g && \
    npm install --loglevel=warn && \

    # `nohup node bin/spacy >/dev/null 2>/dev/null &` && \
    # sleep 5 && \
    # npm test && \
    npm prune --production && \

    rm -r /root/.cache && \
    rm -r /root/.npm

# Bundle app source
COPY ./src/ .
COPY ./entry/services.yml /services.yml

EXPOSE ${PORT}

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["pm2-docker", "/services.yml"]
