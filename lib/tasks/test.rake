# frozen_string_literal: true

# Prepare the test DB manually when needed:
#   RAILS_ENV=test bundle exec rake db:prepare
# Do not enhance `test` with db:test:prepare — purging while a connection is
# open fails on PostgreSQL with PG::ObjectInUse.
