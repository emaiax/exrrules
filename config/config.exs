import Config

if config_env() == :test do
  config :mix_test_watch, clear: true
end
