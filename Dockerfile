FROM alpine:3.13 as build

ENV TOX_VERSION v0.2.12

RUN apk add libsodium-dev libvpx-dev opus-dev cmake autoconf libtool automake gcc g++ libconfig-dev make file linux-headers git
RUN mkdir -p /build
RUN cd /build && \
 git clone https://github.com/TokTok/c-toxcore -b ${TOX_VERSION} c-toxcore && \
 cd c-toxcore && \
 autoreconf -vif && ./configure --enable-static=true --disable-shared --enable-daemon --enable-dht-bootstrap && \
 make -j2

FROM alpine:3.13
RUN apk add libsodium libconfig bash py3-jinja2 py3-requests
RUN mkdir -p /opt/tox /var/lib/tox-bootstrapd /etc

COPY --from=build /build/c-toxcore/build/tox-bootstrapd /opt/tox/
COPY --from=build /build/c-toxcore/other/bootstrap_daemon/tox-bootstrapd.conf /opt/tox/tox-bootstrapd.conf

ENV NODES_URL https://nodes.tox.chat/json
ENV PORT 33445
ENV KEYS_FILE_PATH '/var/lib/tox-bootstrapd/keys'
ENV PID_FILE_PATH '/var/run/tox-bootstrapd/tox-bootstrapd.pid'
ENV ENABLE_IPV6 true
ENV ENABLE_IPV4_FALLBACK true
ENV ENABLE_LAN_DISCOVERY false
ENV ENABLE_TCP_RELAY true
ENV TCP_RELAY_PORTS "[3389,33456]"
ENV ENABLE_MOTD true
ENV MOTD tox-bootstrapd

ADD entrypoint.sh /entrypoint.sh
ADD tox-bootstrapd.conf.j2 /opt/tox/tox-bootstrapd.conf.j2
ADD render.py /opt/tox/render.py
RUN chmod +x /entrypoint.sh /opt/tox/render.py

ENTRYPOINT /entrypoint.sh
