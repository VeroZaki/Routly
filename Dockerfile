FROM ruby:3.3.10-slim

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock *.gemspec ./
COPY lib/routly/version.rb lib/routly/version.rb

RUN bundle install

COPY . .

RUN bundle install

CMD ["bundle", "exec", "routly"]
