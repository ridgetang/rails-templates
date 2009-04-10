# Twitter App Generator
# by Michael Bleigh
#
# Build the complete skeleton for a Twitter application using
# TwitterAuth. This generator will automatically build the
# basics for an OAuth-based Twitter application and will prompt
# you for your OAuth credentials.
#
# It also includes the basics that I like to use in every app,
# including SASS for CSS, RSpec, Factory Girl, and Remarkable.
# Also jRails, can't forget that!

app_name = ask("What is your application called?")
puts "\nBefore this generator runs you will need to register your Twitter application for OAuth at http://twitter.com/oauth_clients, then enter the consumer key and secret below:\n\n"
consumer_key = ask("OAuth Consumer Key:")
consumer_secret = ask("OAuth Consumer Secret:")

run "rm public/index.html"
run "rm public/images/rails.png"
run "rm README"
run "cp config/database.yml config/database.yml.example"

file '.gitignore', <<-END
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
END

git :init
git :add => "."
git :commit => '-m "Initial commit."'

gem 'haml', :version => '>= 2.0.6'
gem 'twitter-auth', :lib => 'twitter_auth'
gem 'cucumber'
gem 'rspec', :lib => false
gem 'rspec-rails', :lib => false
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
gem 'carlosbrando-remarkable', :lib => 'remarkable', :source => 'http://gems.github.com'
gem 'webrat'

plugin 'jrails', :git => 'git://github.com/aaronchi/jrails.git ', :submodule => true
plugin 'uberkit', :git => 'git://github.com/mbleigh/uberkit.git', :submodule => true

generate('twitter_auth')
generate('rspec')
generate('cucumber')
generate('rspec_controller', 'static')

file 'app/views/layouts/master.html.erb', <<-TEMPLATE
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8"/>
    <title>#{app_name} - <%= @title || "Powered by TwitterAuth" %></title>
    <%= stylesheet_link_tag 'master' %>
  </head>
  <body>
    <div id='wrapper'>
      <div id='header'>
        <h1>#{app_name}</h1>
        
        <div id='user_bar'>
          <% if logged_in? %>
            <%= image_tag(current_user.profile_image_url, :width => 24, :height => 24) %> Logged in as <strong>@<%= current_user.login %></strong>. <%= link_to 'Log out', '/logout' %>
          <% else %>
            <%= link_to 'Login via Twitter', '/login' %>
          <% end %>
        </div>
        <div class='clearfix'></div>
      </div>
      <div id='contents'>
        <%= yield %>
      </div>
    </div>
    <div id='footer'>
      Copyright &copy; 2009 #{app_name}. Powered by <%= link_to 'TwitterAuth', 'http://mbleigh.com/twitter-auth', :target => '_blank' %>.
    </div>
  </body>
</html>
TEMPLATE

file 'app/views/static/index.html.erb', <<-TEMPLATE
<h2>Welcome to Your Twitter Application!</h2>

<p>You have successfully created a Twitter-ready application! To test it out just click on <strong>Login via Twitter</strong> above. You should be taken to Twitter and then back here where it will tell you that you are logged in!</p>

<p>This template doesn't assume anything about how you want to build your application other than that you want to use Twitter authentication to do it, so you can generate any controllers, models, and anything else you like! You can tie it back to Twitter accounts simply by adding associations etc. to <code>app/models/user.rb</code>.</p>
TEMPLATE

file 'public/stylesheets/sass/master.sass', <<-SASS
body
  :font-family Arial, sans-serif
  :background #cef
  :margin 0
  :padding 0
  :color #333

a
  :color #06b
  :font-weight bold

.clearfix
  :clear both

#wrapper
  :background white
  :padding 1.5em 2em
  :width 55em
  :-moz-border-radius 1em
  :-webkit-border-radius 1em
  :border-radius 1em
  :margin 1em auto 0.5em

#footer
  :text-align center
  :font-size 0.8em
  :color #666
  :padding-bottom 1.5em

#header
  h1
    :float left
    :font-size 3em
    :margin 0
    :padding 0
    :color #057
    :margin-bottom 0.3em
  #user_bar
    :float right
    :margin-top 1.2em
    img
      :vertical-align middle

p
  :line-height 150%
SASS

file 'app/controllers/application_controller.rb', <<-RUBY
class ApplicationController < ActionController::Base
  layout 'master'
end
RUBY

run "cp config/twitter_auth.yml config/twitter_auth.yml.example"

file 'config/twitter_auth.yml', <<-YAML
development:
  strategy: oauth
  oauth_consumer_key: "#{consumer_key}"
  oauth_consumer_secret: "#{consumer_secret}"
  base_url: "http://twitter.com"
  api_timeout: 10
  remember_for: 14 # days
  oauth_callback: "http://localhost:3000/oauth_callback"
test:
  strategy: oauth
  oauth_consumer_key: "#{consumer_key}"
  oauth_consumer_secret: "#{consumer_secret}"
  base_url: "http://twitter.com"
  api_timeout: 10
  remember_for: 14 # days
  oauth_callback: "http://localhost:3000/oauth_callback"
production:
  strategy: oauth
  oauth_consumer_key: "#{consumer_key}"
  oauth_consumer_secret: "#{consumer_secret}"
  base_url: "http://twitter.com"
  api_timeout: 10
  remember_for: 14 # days
YAML

route "map.root :controller => 'static', :action => 'index'"
route "map.static '/:action', :controller => 'static'"

git :add => '.'
git :commit => '-m "Adding in templates, gems, and plugins."'

if yes?("Run rake gems:install? (yes/no)")
  rake("gems:install")
end

if yes?("Create and migrate databases now? (yes/no)")
  rake("db:create:all")
  rake("db:migrate")
end

