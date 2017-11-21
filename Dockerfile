FROM library/ruby:2.2.8

RUN apt-get update -qq
RUN apt-get install -y build-essential libpq-dev

RUN mkdir -p /usr/src/app
COPY . /usr/src/app/
WORKDIR /usr/src/app

RUN bundle install
