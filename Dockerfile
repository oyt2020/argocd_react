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

# 1단계: React 앱 빌드 (기존과 동일)
FROM node:20-alpine as build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install --ignore-scripts
COPY . .
RUN npm run build

# 2단계: Nginx + VTS 모듈 컴파일 및 실행 환경 구성
FROM nginx:1.25.3-alpine as production-stage

# 빌드에 필요한 도구 설치
RUN apk add --no-cache --virtual .build-deps \
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

# Nginx VTS 모듈 소스 다운로드 및 컴파일
RUN mkdir -p /usr/src && \
    cd /usr/src && \
    curl -L https://github.com/vozlt/nginx-module-vts/archive/refs/tags/v0.2.2.tar.gz -o vts.tar.gz && \
    tar -zxvf vts.tar.gz && \
    CONFARGS=$(nginx -V 2>&1 | grep "configure arguments:" | sed 's/[^*]*configure arguments: //') && \
    curl -O http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
    tar -zxvf nginx-$NGINX_VERSION.tar.gz && \
    cd nginx-$NGINX_VERSION && \
    ./configure $CONFARGS --add-module=/usr/src/nginx-module-vts-0.2.2 && \
    make && make install

# --- 보안 및 실행 설정 ---

# 1. 빌드된 React 결과물 복사
COPY --from=build-stage /app/dist /usr/share/nginx/html
# 2. 작성하신 default.conf 복사
COPY default.conf /etc/nginx/conf.d/default.conf

# 3. 비루트(Non-root) 사용자 권한 설정 (SonarQube 보안 대응)
RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    chown -R nginx:nginx /usr/share/nginx/html

# 4. 사용자 전환
USER nginx

# 8080 포트로 변경 권장 (Non-root는 1024 이하 포트 권한이 없음)
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]