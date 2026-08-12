ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)
require "bundler/setup"
Bundler.require(:default)

# Load .env in development/test so ENV is set before config (e.g. database.yml)
if ENV["RAILS_ENV"].nil? || %w[development test].include?(ENV["RAILS_ENV"])
  begin
    require "dotenv/load"
  rescue LoadError
    # dotenv-rails not installed (e.g. production)
  end
end
