# coding: utf-8

# rails application template for generating customized rails apps
#
# == requires ==
#
# * rails 2.3+, rspec, cucumber, culerity (langalex-culerity gem), machinist
#
# == a newly generated app using this template comes with ==
#
# * working user registration/login via clearance, cucumber features to verify that it works
# * rspec/cucumber/culerity for testing
# * thinking_sphinx configuration
# * german localization
# * capistrano deployment script
# * jquery and blueprint css set up
# * a blueprints.rb for machinist
#
# == how to use ==
#
# * install the required gems (and jruby for culerity)
# * generate a new app: rails my_new_app -m /path/to/upstream_rails_application_template.rb
# * run the features to verify everything is working: rake features
#
# == TODO ==
# * add forgot password method
# * make registration/login use resource_controller

app_name = `pwd`.split('/').last.strip

run "rm README"
run "rm -rf test"
run "rm public/index.html"
run "rm public/favicon.ico"
run "rm public/robots.txt"
run "rm public/images/rails.png"
run "rm -f public/javascripts/*"
  
# get jquery and plugins
run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.3.2.js > public/javascripts/jquery.js"
run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"
run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/methods/date.js > public/javascripts/date.js"
run "curl -L http://www.kelvinluck.com/assets/jquery/datePicker/v2/demo/scripts/jquery.datePicker.js > public/javascripts/jquery.datePicker.js"
run "curl -L http://www.kelvinluck.com/assets/jquery/datePicker/v2/demo/styles/datePicker.css > public/stylesheets/datePicker.css"

# blueprint/css

run "curl -L http://github.com/joshuaclayton/blueprint-css/tarball/master > public/stylesheets/blueprint.tar && tar xf public/stylesheets/blueprint.tar"
run 'rm public/stylesheets/blueprint.tar'
blueprint_dir = Dir.entries('.').grep(/blueprint/).first
run "mv #{blueprint_dir}/blueprint/*.css public/stylesheets"
run "rm -rf #{blueprint_dir}"

# environment

file 'config/environment.rb', <<-FILE
RAILS_GEM_VERSION = '2.3.3' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # config.load_paths += %W( \#{RAILS_ROOT}/extras )
  # config.plugins = [:ssl_requirement, :all ]
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
  # config.time_zone = 'UTC'

  config.i18n.default_locale = :en
end

FILE

# application layout

file 'app/views/layouts/application.html.erb', <<-FILE
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title>#{app_name}</title>
    <%= stylesheet_link_tag 'screen', 'datePicker', :media => 'screen, projection' %>
    <%= stylesheet_link_tag 'print', :media => 'print' %>
    <!--[if IE]>
      <%= stylesheet_link_tag 'ie', :media => 'all' %>
    <![endif]-->
    
    <%= javascript_include_tag 'jquery', 'jquery.form.js', 'date', 'jquery.datePicker.js', :cache => true %>
    <%= yield(:head) %>
    <script type="text/javascript">
      $(function() {
        <%= yield(:jquery) %>
      });
    </script>
  </head>
  <body>
    <div id="navigation">
      <ul>
        <%- if current_user -%>
          <li><%= link_to 'Home', account_path %></li>
          <li><%= link_to 'Log out', user_session_path, :method => :delete %></li>
        <%- else -%>
          <li><%= link_to 'Home', root_path %></li>
          <li><%= link_to 'Sign up', new_user_path %></li>
          <li><%= link_to 'Log in', new_user_session_path %></li>
        <%- end -%>
      </ul>
    </div>
    <div id="content">
      <%- if flash[:notice] -%>
        <div id="flash"><%= flash[:notice] %></div>
      <%- end -%>
      <%= yield %>
    </div>
  </body>
</html>
FILE

# Copy database.yml for distribution use
run "rm config/database.yml"
file "config/database.yml", <<-FILE
development:
  adapter: mysql
  database: #{app_name}_development
  encoding: utf8

test:
  adapter: mysql
  database: #{app_name}_test
  encoding: utf8

production:
  username: rails
  password: 
  adapter: mysql
  database: #{app_name}_production
  pool: 5
  encoding: utf8

FILE
run "cp config/database.yml config/database.yml.example"
rake 'db:create'


# routes

file 'config/routes.rb', <<-FILE
ActionController::Routing::Routes.draw do |map|

end
FILE

# Set up .gitignore files
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
run %{find . -type d -empty | grep -v "vendor" | grep -v ".git" | grep -v "tmp" | xargs -I xxx touch xxx/.gitignore}
file '.gitignore', <<-END
.DS_Store
log/*.log
log/*.pid
tmp/**/*
config/database.yml
db/schema.rb
config/*sphinx.conf
db/sphinx
END

# gems
gem 'mislav-will_paginate', :version => '~> 2.2.3', :lib => 'will_paginate',  :source => 'http://gems.github.com'
gem "thoughtbot-clearance", :lib     => 'clearance', :source  => 'http://gems.github.com', :version => '0.6.4'
gem 'giraffesoft-resource_controller', :lib => 'resource_controller', :source => 'http://gems.github.com'

rake 'gems:install', :sudo => true

# plugins
# plugin 'jrails', :git => 'git://github.com/aaronchi/jrails.git'
plugin 'exceptional', :git => 'git://github.com/contrast/exceptional.git'
run 'cp vendor/plugins/exceptional/exceptional.yml config/exceptional.yml'
# plugin 'thinking-sphinx', :git => 'git://github.com/freelancing-god/thinking-sphinx.git'

# generators
generate("rspec")
generate("rspec-rails")
run "rm -rf stories"
generate("cucumber")
run "rm features/step_definitions/webrat_steps.rb"
generate("culerity")
generate("clearance")

# enable culerity, disable webrat

file 'features/support/env.rb', <<-FILE
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
require 'cucumber/rails/world'
require 'cucumber/formatters/unicode'
require 'cucumber/rails/rspec'

require 'culerity'

require 'machinist'
require RAILS_ROOT + '/spec/blueprints'

FILE

# machinist

file 'spec/blueprints.rb', <<-FILE
  User.blueprint do
    login "joe"
    password "testtest"
    password_confirmation "testtest"
  end
FILE

# skip cucumber/rspec load errors on production server

[:cucumber, :rspec].each do |service|
  file "lib/tasks/#{service}.rake", <<-FILE
begin
  #{File.read("lib/tasks/#{service}.rake")}
rescue LoadError => e
  STDERR.puts "could not load #{service}."
end
FILE
end


# login/signup features

file 'features/log_in.feature', <<-FILE
Feature: log in
  In order to use the system
  As a user
  I want to log in
  
Scenario: log in
  Given a user "alex" with the password "testtest"
  When I go to the start page
  And I follow "Log in"
  And I fill in "alex" for "Login"
  And I fill in "testtest" for "Password"
  And I press "Login"
  Then I should see "Welcome alex"
  And I should see "Login successful!"

Scenario: log out
  Given a user "alex" with the password "testtest"
  And "alex" is logged in
  When I go to the account page
  And I follow "Log out"
  Then I should see "Log in"
  And I should see "Logout successful!"
  
Scenario: edit account
  Given a user "alex" with the password "testtest"
  And "alex" is logged in
  When I go to the account page
  And I follow "Edit Account"
  And I fill in "joe" for "Login"
  And I press "Update"
  Then I should see "Account updated!"
FILE

file 'features/sign_up.feature', <<-FILE
Feature: sign up
  In order to use all the platform's features
  As a user
  I want to sign up
  
Scenario: sign up successfully
  When I go to the start page
  And I follow "Sign up"
  And I fill in "alex" for "Login"
  And I fill in "testtest" for "Password"
  And I fill in "testtest" for "Password confirmation"
  And I press "Register"
  Then I should see "Welcome alex"

Scenario: signing up fails because login is taken
  Given a user "alex"
  When I go to the start page
  And I follow "Sign up"
  And I fill in "alex" for "Login"
  And I fill in "testtest" for "Password"
  And I fill in "testtest" for "Password confirmation"
  And I press "Register"
  Then I should not see "Welcome alex"
  And I should see "Login ist bereits vergeben"
FILE

file 'features/step_definitions/user_steps.rb', <<-FILE
Before do
  User.delete_all
end

Given /^a user "(.+)" with the password "(.+)"$/ do |login, password|
  User.make :login => login, :password => password, :password_confirmation => password
end

Given /a user "([^"]+)"$/ do |login|
  User.make :login => login
end

Given /^"([^"]+)" is logged in$/ do |login|
  When 'I go to the start page'
  When 'I follow "Log in"'
  When "I fill in \\\"\#{login}\\\" for \\\"Login\\\""
  When 'I fill in "testtest" for "Password"'
  When 'I press "Login"'
end
FILE

file 'features/support/paths.rb', <<-FILE
def path_to(page_name)
  case page_name
  when /the start page/i
    root_path
  when /the account page/i
    account_path
  else
    raise "Can't find mapping from \"\#{page_name}\" to a path."
  end
end
FILE

# migrations
rake "db:migrate"


# german localization

file 'config/locales/de.yml', <<-FILE
# German translations for Ruby on Rails 
# by Clemens Kofler (clemens@railway.at)

de:
  date:
    formats:
      default: "%d.%m.%Y"
      short: "%e. %b"
      long: "%e. %B %Y"
      only_day: "%e"

    day_names: [Sonntag, Montag, Dienstag, Mittwoch, Donnerstag, Freitag, Samstag]
    abbr_day_names: [So, Mo, Di, Mi, Do, Fr, Sa]
    month_names: [~, Januar, Februar, März, April, Mai, Juni, Juli, August, September, Oktober, November, Dezember]
    abbr_month_names: [~, Jan, Feb, Mär, Apr, Mai, Jun, Jul, Aug, Sep, Okt, Nov, Dez]
    order: [ :day, :month, :year ]
  
  time:
    formats:
      default: "%A, %e. %B %Y, %H:%M Uhr"
      short: "%e. %B, %H:%M Uhr"
      long: "%A, %e. %B %Y, %H:%M Uhr"
      time: "%H:%M"

    am: "vormittags"
    pm: "nachmittags"
      
  datetime:
    distance_in_words:
      half_a_minute: 'eine halbe Minute'
      less_than_x_seconds:
        zero: 'weniger als 1 Sekunde'
        one: 'weniger als 1 Sekunde'
        other: 'weniger als {{count}} Sekunden'
      x_seconds:
        one: '1 Sekunde'
        other: '{{count}} Sekunden'
      less_than_x_minutes:
        zero: 'weniger als 1 Minute'
        one: 'weniger als eine Minute'
        other: 'weniger als {{count}} Minuten'
      x_minutes:
        one: '1 Minute'
        other: '{{count}} Minuten'
      about_x_hours:
        one: 'etwa 1 Stunde'
        other: 'etwa {{count}} Stunden'
      x_days:
        one: '1 Tag'
        other: '{{count}} Tage'
      about_x_months:
        one: 'etwa 1 Monat'
        other: 'etwa {{count}} Monate'
      x_months:
        one: '1 Monat'
        other: '{{count}} Monate'
      about_x_years:
        one: 'etwa 1 Jahr'
        other: 'etwa {{count}} Jahre'
      over_x_years:
        one: 'mehr als 1 Jahr'
        other: 'mehr als {{count}} Jahre'
      
  number:
    format:
      precision: 2
      separator: ','
      delimiter: '.'
    currency:
      format:
        unit: '€'
        format: '%n%u'
        separator: 
        delimiter: 
        precision: 
    percentage:
      format:
        delimiter: ""
    precision:
      format:
        delimiter: ""
    human:
      format:
        delimiter: ""
        precision: 1

  support:
    array:
      sentence_connector: "und"
      skip_last_comma: true
        
  activerecord:
    errors:
      template:
        header:
          one:    "Konnte dieses {{model}} Objekt nicht speichern: 1 Fehler."
          other:  "Konnte dieses {{model}} Objekt nicht speichern: {{count}} Fehler."
        body: "Bitte überprüfen Sie die folgenden Felder:"

      messages:
        inclusion: "ist kein gültiger Wert"
        exclusion: "ist nicht verfügbar"
        invalid: "ist nicht gültig"
        confirmation: "stimmt nicht mit der Bestätigung überein"
        accepted: "muss akzeptiert werden"
        empty: "muss ausgefüllt werden"
        blank: "muss ausgefüllt werden"
        too_long: "ist zu lang (nicht mehr als {{count}} Zeichen)"
        too_short: "ist zu kurz (nicht weniger als {{count}} Zeichen)"
        wrong_length: "hat die falsche Länge (muss genau {{count}} Zeichen haben)"
        taken: "ist bereits vergeben"
        not_a_number: "ist keine Zahl"
        greater_than: "muss größer als {{count}} sein"
        greater_than_or_equal_to: "muss größer oder gleich {{count}} sein"
        equal_to: "muss genau {{count}} sein"
        less_than: "muss kleiner als {{count}} sein"
        less_than_or_equal_to: "muss kleiner oder gleich {{count}} sein"
        odd: "muss ungerade sein"
        even: "muss gerade sein"
      models:

FILE


# capistrano
capify!

file 'config/deploy.rb', <<-FILE
default_run_options[:pty] = true
set :application, "#{app_name}"
set :repository,  "git@github.com:#{ask('GitHub username for the git repository?')}/#{app_name}.git"
set :scm, "git"
set :ssh_options, { :forward_agent => true }
set :use_sudo, false
set :domain, "#{ask('What is the servername for deployment?')}"
set :user, "rails"

set :branch, "master"
set :deploy_via, :remote_cache

set :deploy_to, "/var/www/\#{application}"

role :app, domain
role :web, domain
role :db,  domain, :primary => true

desc 'restart'
deploy.task :restart, :roles => :app do
  run "touch \#{current_path}/tmp/restart.txt"
end

after 'deploy:finalize_update', :roles => :app do
  run "ln -s \#{shared_path}/config/database.yml \#{release_path}/config/database.yml"
end

FIL
