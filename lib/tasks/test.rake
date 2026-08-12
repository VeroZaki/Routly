# frozen_string_literal: true

# Ensure test DB exists and has schema before running tests
task "test:prepare" => ["db:test:prepare"]

if Rake::Task.task_defined?("test")
  Rake::Task["test"].enhance(["db:test:prepare"])
end
