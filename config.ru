require 'dashing'

configure do
  set :auth_token, 'NOT_PROTECTED'
  helpers do
    def protected!
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application