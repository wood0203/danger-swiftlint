ARG SWIFT_VERSION=latest
FROM 41772ki/swift-mint:${SWIFT_VERSION}

LABEL repository="https://github.com/417-72KI/danger-swiftlint"
LABEL homepage="https://github.com/417-72KI/danger-swiftlint"
LABEL maintainer="417-72KI <417.72ki@gmail.com>"

# Install NPM
RUN apt-get update \
    && apt-get install -y npm curl \
    && npm install -g n \
    && n stable \
    && apt-get purge -y npm

# Install Danger-JS(Danger-Swift depends)
ARG DANGER_JS_REVISION=master
ENV DANGER_JS_REVISION=${DANGER_JS_REVISION}
RUN npm install -g danger | tee /var/log/danger-js-build.log \
    && danger-js --version > /.danger-js_revision

# Install Danger-Swift
# Error occurs on running(https://github.com/danger/swift/issues/309)
# RUN mint install danger/swift@${DANGER_SWIFT_REVISION}
ARG DANGER_SWIFT_REVISION=master
ARG DANGER_SWIFT_COMMIT=2be8668364380e0bef4b21feaae6ae30a4f9688f # 여기서 커밋 해시를 지정
ENV DANGER_SWIFT_REVISION=${DANGER_SWIFT_REVISION}
ENV DANGER_SWIFT_COMMIT=${DANGER_SWIFT_COMMIT}

RUN git clone https://github.com/danger/danger-swift.git ~/danger-swift \
    && cd ~/danger-swift \
    && git checkout ${DANGER_SWIFT_COMMIT} \  # 지정한 커밋 해시로 체크아웃
    && git rev-parse HEAD > /.danger-swift_revision \
    && sed -i -e 's/let isDevelop = true/let isDevelop = false/g' ~/danger-swift/Package.swift \
    && make install | tee /var/log/danger-swift-build.log \
    && rm -rf ~/danger-swift

# Install SwiftLint
ARG SWIFT_LINT_REVISION=main
ENV SWIFT_LINT_REVISION=${SWIFT_LINT_REVISION}
RUN mint install --verbose realm/SwiftLint@${SWIFT_LINT_REVISION} | tee /var/log/swiftlint-build.log \
    && swiftlint --version > /.swiftlint_revision

ADD entrypoint.sh /usr/local/bin/entrypoint
ADD versions.sh /usr/local/bin/show-versions

ENTRYPOINT [ "entrypoint" ]
CMD [ "ci" ]
