FROM ubuntu:14.04

MAINTAINER ivan@lagunovsky.com

ENV NGINX_VERSION 1.11.2
ENV NPS_VERSION 1.11.33.2
ENV NGINX_USER root
ENV SETUP_DIR /var/cache/nginx

RUN apt-get update && apt-get upgrade -y --no-install-recommends && apt-get install -y \
    gcc \
    g++ \
    wget \
    libpcre3-dev \
    zlib1g-dev \
    openssl \
    build-essential \
    zlib1g-dev \
    libssl-dev \
    libgd2-xpm-dev \
    libgeoip-dev \
    --no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y curl

RUN mkdir -p ${SETUP_DIR}

# Prepare module
RUN cd ${SETUP_DIR} \
    && wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VERSION}-beta.tar.gz --no-check-certificate \
    && tar zxvf v${NPS_VERSION}-beta.tar.gz \
    && cd ngx_pagespeed-${NPS_VERSION}-beta \
    && wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz --no-check-certificate \
    && tar -xzvf ${NPS_VERSION}.tar.gz

# Install nginx
RUN wget -P ${SETUP_DIR} http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
RUN tar -zxvf ${SETUP_DIR}/nginx-${NGINX_VERSION}.tar.gz -C ${SETUP_DIR}
RUN cd ${SETUP_DIR}/nginx-${NGINX_VERSION} && ./configure \
    --prefix=/opt/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/lib/nginx/body \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-proxy-temp-path=/var/lib/nginx/proxy \
    --with-http_ssl_module \
    --with-openssl-opt="enable-tlsext" \
    --with-cc=/usr/bin/gcc \
    --with-poll_module \
    --with-select_module \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_geoip_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-file-aio \
    --with-ipv6 \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-http_slice_module \
    --with-http_v2_module \
    --add-module=${SETUP_DIR}/ngx_pagespeed-${NPS_VERSION}-beta

RUN cd ${SETUP_DIR}/nginx-${NGINX_VERSION} && make && make install

COPY config/conf.d/ /etc/nginx/conf.d/
COPY config/sites-enabled/ /etc/nginx/sites-enabled/
COPY config/nginx.conf /etc/nginx/nginx.conf

RUN mkdir /usr/share/nginx \
    && ln -sf /opt/nginx/html /usr/share/nginx/html

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false \
    curl \
    gcc \
    g++ \
    wget \
    libpcre3-dev \
    zlib1g-dev \
    openssl \
    build-essential \
    zlib1g-dev \
    libssl-dev \
    libgd2-xpm-dev
RUN apt-get clean all
RUN rm -rf ${SETUP_DIR}/{nginx,ngx_pagespeed}
RUN rm -rf /var/lib/apt/lists/*

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
