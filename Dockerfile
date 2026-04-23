## 1단계: 빌드 스테이지
#FROM node:20-alpine as build-stage
#WORKDIR /app
#COPY package*.json ./
#RUN npm install --ignore-scripts
#COPY . .
#RUN npm run build
#
## 2단계: 실행 스테이지 (Nginx 사용) , VTS 모듈이 포함된 이미지
#FROM v9at0sl/nginx-vts-alpine:latest
## 테스트용 취약 패키지
## RUN apk add --no-cache curl
## 빌드된 결과물(dist)을 nginx의 기본 정적 파일 폴더로 복사
#COPY --from=build-stage /app/dist /usr/share/nginx/html
#
#COPY default.conf /etc/nginx/conf.d/default.conf
#
#RUN touch /var/run/nginx.pid && \
#    chown -R nginx:nginx /var/run/nginx.pid && \
#    chown -R nginx:nginx /var/cache/nginx && \
#    chown -R nginx:nginx /var/log/nginx && \
#    chown -R nginx:nginx /etc/nginx/conf.d
#
#USER nginx
#
## Nginx 포트 80 노출
#EXPOSE 8000
#CMD ["nginx", "-g", "daemon off;"]

# 1단계: 빌드 스테이지
FROM node:20-alpine as build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install --ignore-scripts
COPY . .
RUN npm run build

# 2단계: Nginx + VTS 모듈 컴파일 스테이지
FROM nginx:1.25.3-alpine as production-stage

RUN apk update && apk upgrade --no-cache

ARG NGINX_VERSION=1.25.3

# 컴파일에 필요한 도구 및 라이브러리 설치
RUN apk add --no-cache \
    gcc \
    libc-dev \
    make \
    openssl-dev \
    pcre-dev \
    zlib-dev \
    linux-headers \
    curl \
    gnupg \
    libxslt-dev \
    gd-dev \
    geoip-dev

# 소스 다운로드 및 컴파일
RUN mkdir -p /usr/src && cd /usr/src && \
    # VTS 모듈 다운로드
    curl -L https://github.com/vozlt/nginx-module-vts/archive/refs/tags/v0.2.2.tar.gz -o vts.tar.gz && \
    tar -zxvf vts.tar.gz && \
    # Nginx 소스 다운로드
    curl -L https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz && \
    tar -zxvf nginx.tar.gz && \
    # 컴파일 설정 및 빌드
    cd nginx-$NGINX_VERSION && \
    ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_v2_module \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --add-module=/usr/src/nginx-module-vts-0.2.2 && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install

# --- 보안 및 실행 설정 ---

# 1. 빌드된 결과물 복사
COPY --from=build-stage /app/dist /usr/share/nginx/html
COPY default.conf /etc/nginx/conf.d/default.conf

# 2. 캐시 디렉토리 생성 및 권한 부여 (Non-root 실행 필수 작업)
RUN mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/proxy_temp && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    chown -R nginx:nginx /usr/share/nginx/html

# 3. 사용자 전환
USER nginx

# 8080 포트 사용 (Non-root 권한 이슈 방지)
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]