FROM ruby:2.7.2-alpine as builder
RUN apk --update add build-base tzdata postgresql-dev libxslt-dev libxml2-dev
RUN gem install bundler
WORKDIR /tmp
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
ENV BUNDLE_JOBS=4
RUN bundle install
RUN apk del build-base

FROM ruby:2.7.2-alpine
RUN apk --update add \
    bash \
    postgresql-dev \
    tzdata
WORKDIR /tmp
RUN gem install bundler
COPY --from=builder /usr/local/bundle /usr/local/bundle
ENV APP_HOME /myapp
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME
COPY . $APP_HOME
RUN adduser -D icecreamtruck
RUN chown icecreamtruck $APP_HOME/tmp/pids
USER icecreamtruck
CMD ["bundler","exec","rails","s"]
