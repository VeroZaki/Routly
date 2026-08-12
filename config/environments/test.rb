Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.active_record.maintain_test_schema = false
end
