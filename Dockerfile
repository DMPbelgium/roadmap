#syntax=docker/dockerfile:1
FROM ruby:3.0.5 AS build

WORKDIR /opt/roadmap
COPY . .

RUN apt-get update && \
    gem install bundler:2.4.8 && \
    rm -rf vendor/ && \
    rm -f .bundle/config && \
    gem install bundler:2.4.8 && \
    bundle config build.nokogiri --use-system-libraries && \
    bundle config path vendor/bundle && \
    bundle config with pgsql mysql puma && \
    bundle config without test development ci aws && \
    bundle install && \
    rm -rf app/assets/videos && \
    rm -rf app/assets/builds && \
    rm -rf public/assets/ && \
    rm -rf node_modules/ && \
    rm -rf .git/ && \
    rm -rf tmp/ && \
    rm -rf log/ && \
    rm -rf vendor/bundle/ruby/3.0.0/cache/ && \
    rm -rf /usr/local/bundle/cache/ && \
    (bin/wkhtmltopdf || true) &&\
    rm -f vendor/bundle/ruby/3.0.0/gems/wkhtmltopdf-binary-0.12.6.6/bin/*.gz && \
    mv ./ugent/public/* ./public && \
    mv bin/rails_without_spring bin/rails

FROM --platform=$BUILDPLATFORM ruby:3.0.5-slim

COPY --from=build /opt/roadmap /opt/roadmap
COPY --from=build /usr/local/bundle /usr/local/bundle

RUN apt-get update && \
  apt-get -y install libpq5 libmariadb3 libyaml-0-2 libxml2 openssl bison libjpeg62-turbo libpng16-16 imagemagick libxrender1 libxext6/stable

# for testing purpose
#CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
