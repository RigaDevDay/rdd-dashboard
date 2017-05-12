FROM ruby:1.9

RUN apt-get -y -q update
RUN apt-get -y -q install sqlite
RUN apt-get -y -q install libsqlite3-dev
RUN apt-get -y -q install g++ nodejs

RUN mkdir -p /var/lib/sqlite
RUN touch /var/lib/sqlite/rigadevday.db
RUN touch /etc/rigadevday.yml

RUN gem install dashing
RUN bundle install

EXPOSE 3000

CMD ["dashing", "start"]
