#!/bin/sh

# cleans up previous shutdown
rm -f /opt/roadmap/tmp/pids/server.pid

# Setup standard environment variables
export MALLOC_ARENA_MAX=2
export RAILS_LOG_TO_STDOUT=true

# Setup environment variables for development
export DMP_LOCAL_LOGIN=true
export DB_ADAPTER=mysql2
export DB_PASSWORD=root
export RAILS_ENV=development
export RAILS_SERVE_STATIC_FILES=true
#export EXECJS_RUNTIME=Disabled
export WEB_CONCURRENCY=0
export RAILS_MAX_THREADS=1

# Setup credentials
export EDITOR='echo "recaptcha:" >>'
./bin/rails credentials:edit
export EDITOR='echo "  site_key: \"\"" >>'
./bin/rails credentials:edit
export EDITOR='echo "  secret_key: \"\"" >>'
./bin/rails credentials:edit
#export EDITOR='echo "devise_pepper: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >>'
#./bin/rails credentials:edit
#export EDITOR='echo "dragonfly_secret: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >>'
#./bin/rails credentials:edit

# Configures database
cat <<EOF1 > config/database.yml
production: &defaults
  adapter: <%= ENV['DB_ADAPTER'] || 'postgresql' %>
  encoding: <%= ENV['DB_ADAPTER'] == "mysql2" ? "utf8mb4" : "" %>
  username: root
  password: <%= ENV["DB_PASSWORD"] %>
  host: mysql
  database: roadmap_development
  pool: 16

development:
  <<: *defaults

test:
  <<: *defaults
EOF1

./bin/rails assets:precompile
./bin/rails db:migrate
rdebug-ide --host 0.0.0.0 --port 9000 -- bin/rails server -p 3000 -b 0.0.0.0
