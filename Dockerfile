#syntax=docker/dockerfile:1
FROM ruby:2.7

WORKDIR /opt/roadmap
COPY . .

RUN apt-get update
RUN apt-get -y install nodejs yarnpkg
RUN ln -s /usr/bin/yarnpkg /usr/bin/yarn
RUN bundle install
RUN yarnpkg install
