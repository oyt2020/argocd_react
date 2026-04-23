# 1단계: 빌드 스테이지
FROM node:20-alpine as build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install --ignore-scripts
COPY . .
RUN npm run build

# 2단계: 실행 스테이지 (Nginx 사용) , VTS 모듈이 포함된 이미지
FROM yellowapple/nginx-proxy-vts:alpine
# 테스트용 취약 패키지
# RUN apk add --no-cache curl
# 빌드된 결과물(dist)을 nginx의 기본 정적 파일 폴더로 복사
COPY --from=build-stage /app/dist /usr/share/nginx/html

COPY default.conf /etc/nginx/conf.d/default.conf

# Nginx 포트 80 노출
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]