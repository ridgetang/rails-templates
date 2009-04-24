def commit(message)
  puts

  git :add => '.' # add new files
  git :add => '-u' # remove deleted files
  git :commit => "-m '#{message}'"

  puts
  puts
end

def prompt(question, default)
  response = ask "#{question}: [#{default}]"
  response.blank? ? default : response
end



puts

confirmation = []

application_name = prompt 'Enter a machine-useable application name', ''
confirmation << "Application name is #{application_name}"

default_user       = ''
default_domain     = application_name + '.com' unless application_name.blank?
default_sub_domain = 'www'
default_db_user    = ''
default_db_pass    = ''

production_user       = prompt 'Production server username', default_user
production_domain     = prompt 'Production server domain', default_domain
production_sub_domain = prompt 'Production server sub-domain', default_sub_domain

default_host = production_domain unless production_domain.blank?
default_host = "#{production_sub_domain}.#{default_host}" unless production_sub_domain.blank?

production_host       = prompt 'Production server host', default_host
production_db_user    = prompt 'Production database login', default_db_user
production_db_pass    = prompt 'Production database password', default_db_pass

confirmation << ''
confirmation << "production_user       = #{production_user}"
confirmation << "production_domain     = #{production_domain}"
confirmation << "production_sub_domain = #{production_sub_domain}"
confirmation << "production_host       = #{production_host}"
confirmation << "production_db_user    = #{production_db_user}"
confirmation << "production_db_pass    = #{production_db_pass}"

setup_staging = yes? 'Setup staging server? [y|n]'
confirmation << ''
confirmation << "You do #{'not ' unless setup_staging}want to setup a staging server"

if setup_staging
  staging_user       = prompt 'Staging server username', production_user
  staging_domain     = prompt 'Staging server domain', production_domain
  staging_sub_domain = prompt 'Staging server sub-domain', production_sub_domain
  staging_host       = prompt 'Staging server host', production_host
  staging_db_user    = prompt 'Staging database login', production_db_user
  staging_db_pass    = prompt 'Staging database password', production_db_pass

  confirmation << ''
  confirmation << "staging_user       = #{staging_user}"
  confirmation << "staging_domain     = #{staging_domain}"
  confirmation << "staging_sub_domain = #{staging_sub_domain}"
  confirmation << "staging_host       = #{staging_host}"
  confirmation << "staging_db_user    = #{staging_db_user}"
  confirmation << "staging_db_pass    = #{staging_db_pass}"
end

use_github = yes? 'Host repository on GitHub? [y|n]'
confirmation << ''
confirmation << "This project will #{'not ' unless use_github}be hosted on GitHub"

repository_user = prompt 'GitHub username', production_user if use_github
repository_user ||= production_user
confirmation << ''
confirmation << "repository_user = #{repository_user}"

capistrano_repository = use_github ? 'git://git@github.com:#{user}/#{application}.git' : 'ssh://#{user}@#{host}/home/#{user}/repositories/#{domain}/#{sub_domain}/.git'
origin_repository = use_github ? "git://github.com/#{repository_user}/#{application_name}.git" : "ssh://#{production_user}@#{production_host}/home/#{production_user}/repositories/#{production_domain}/#{production_sub_domain}/.git"

confirmation << ''
confirmation << "capistrano_repository = #{capistrano_repository}"
confirmation << "origin_repository = #{origin_repository}"

puts
confirmation.each { |line| puts line }
puts

if no? 'Before continuing, please verify that these choices are correct. Do wish to proceed? [y|n]'
  exit
end

# end of configuration



messages = []



# Set up git repository and create the initial commit
  run 'touch tmp/.gitignore log/.gitignore vendor/.gitignore'
  file '.gitignore', <<-END
*~
*.cache
Capfile
.DS_Store
*.log
*.pid
*.sw?
*.tmproj
config/database.yml
config/deploy.rb
coverage/*
db/cstore/**
db/*.sqlite3
doc/api
doc/app
doc/*.dot
doc/plugins
log/*.log
log/*.pid
nbproject/**/*
tmp/**/*
END
  git :init
  commit 'Initial commit'



# Add remote origin
  origin_name = use_github ? 'github' : 'dreamhost'
  git :remote => "add #{origin_name} #{origin_repository}"



# Freeze Rails and initialize Capistrano
  freeze!
  capify!
  commit 'Rails froze over'



# Delete unnecessary files
  run 'rm README'
  run 'rm public/index.html'
  run 'rm public/favicon.ico'
  #run 'rm public/robots.txt'
  run 'rm -f public/javascripts/*'
  commit 'Removed non-essential files'



# Copy database.yml for distribution use
  run 'cp config/database.yml config/database.yml.example'
  commit 'Copied default config/database.yml to config/database.yml.example'



# Set up config/database.yml
  database_yaml = %Q{---
local_defaults: &local_defaults
  adapter: sqlite3
  pool: 5
  timeout: 5000

development:
  <<: *local_defaults
  database: db/development.sqlite3

test:
  <<: *local_defaults
  database: db/test.sqlite3

remote_defaults: &remote_defaults
  adapter: mysql
  host: localhost
  username: #{production_db_user}
  password: #{production_db_pass}
  encoding: utf8
  pool: 5
  reconnect: false

production:
  <<: *remote_defaults
  database: #{application_name}_production
}
  database_yaml += %Q{
staging:
  <<: *remote_defaults
  database: #{application_name}_staging
} if setup_staging

  file 'config/database.yml', database_yaml



# @todo: Download CSS framework (or setup asset server)
# @todo: Download JQuery (or setup asset server)
# @todo: Prep staging and production servers (create base directory)



# Confirgure capistrano
  file 'Capfile',
%q{load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'
}


  file 'config/deploy.rb',
%Q{require 'capistrano/ext/multistage'

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

set :use_sudo, false

set :stages, %w(#{'staging ' if setup_staging}production)
set :default_stage, '#{setup_staging ? 'staging' : 'production'}'

before 'deploy:setup', 'db:password'

role :app, host
role :web, host
role :db,  host, :primary => true

namespace :deploy do
  desc 'Default deploy - updated to run migrations'
  task :default do
    set :migrate_target, :latest
    update_code
    migrate
    symlink
    restart
  end

  desc 'Start server'
  task :start do
    send run_method, "cd \#{current_path} && \#{mongrel_rails} cluster::start --config \#{mongrel_cluster_config}"
  end

  desc 'Stop server'
  task :stop do
    send run_method, "cd \#{current_path} && \#{mongrel_rails} cluster::stop --config \#{mongrel_cluster_config}"
  end

  desc 'Restart server'
  task :restart do
    #send run_method, "cd \#{deploy_to}/\#{current_dir} && \#{mongrel_rails} cluster::restart --config \#{mongrel_cluster_config}"
    run "touch \#{current_path}/tmp/restart.txt"
  end

  desc 'Run this after every successful deployment'
  task :after_default do
    cleanup
  end
end

task :after_update_code do
  run "ln -nfs \#{shared_path}/config/database.yml \#{release_path}/config/database.yml"
end

namespace :db do
  desc 'Create database password in shared path'
  task :password do
    set :db_password, Proc.new { Capistrano::CLI.password_prompt 'Remote database password: ' }
    run "mkdir -p \#{shared_path}/config"
    put db_password, "\#{shared_path}/config/dbpassword"
  end
end
}


if setup_staging
  file 'config/deploy/staging.rb',
%Q{# Who are we?
set :user, '#{staging_user}'

# Project hosting details
set :application, '#{application_name}'
set :domain, '#{staging_domain}'
set :sub_domain, '#{staging_sub_domain}'
set :host, '#{staging_host}'
set :deploy_to, "/home/\#{user}/public_html/\#{domain}/\#{sub_domain}"
set :deploy_via, :remote_cache

# For migrations
set :rails_env, 'staging'

# Deploy details
set :scm, :git
set :repository, capistrano_repository
set :branch, 'master'
set :git_shallow_clone, 1
set :scm_verbose, true
}
end


  file 'config/deploy/production.rb',
%Q{# Who are we?
set :user, '#{production_user}'

# Project hosting details
set :application, '#{application_name}'
set :domain, '#{production_domain}'
set :sub_domain, '#{production_sub_domain}'
set :host, '#{production_host}'
set :deploy_to, "/home/\#{user}/public_html/\#{domain}/\#{sub_domain}"
set :deploy_via, :remote_cache

# For migrations
set :rails_env, 'production'

# Deploy details
set :scm, :git
set :repository, capistrano_repository
set :branch, 'master'
set :git_shallow_clone, 1
set :scm_verbose, true
}

commit 'Configured Capistrano'



# Add gems
  #gem 'binarylogic-authlogic', :lib => 'authlogic', :source => 'http://gems.github.com'
  #rake 'gems:install'



# Add plugins
  plugin 'brynary-rack_bug', :git => 'git://github.com/brynary/rack-bug.git', :submodule => true



# Initialize submodules
  #git :submodule => 'init'
  #commit ''



# @future_reference: Set up session store initializer
#  initializer 'session_store.rb', <<-END
#ActionController::Base.session = { :session_key => '_#{(1..6).map { |x| (65 + rand(26)).chr }.join}_session', :secret => '#{(1..40).map { |x| (65 + rand(26)).chr }.join}' }
#ActionController::Base.session_store = :active_record_store
#END



# Set up sessions, RSpec, user model, OpenID, etc and run migrations
  rake 'db:create'
  rake 'db:sessions:create'
  #generate :scaffold, 'person', 'first_name:string', 'last_name:string', 'born_at:datetime'
  rake 'db:migrate'
  commit 'Ran boilerplate rake tasks'



# Configure home page
  #route "map.root :controller => 'people'"
  #commit 'Setup default page (/)'



# Place an empty .gitignore in any remaining empty directories
  run %{find . -type d -empty | grep -v 'vendor' | grep -v '.git' | grep -v 'tmp' | xargs -I xxx touch xxx/.gitignore}
  commit 'Added .gitignores to track empty directories (necessary evil until .gitnotice becomes a reality)'



# Dump messages to screen
  if messages.any?
    puts
    messages.each { |line| puts line }
    puts
  end

