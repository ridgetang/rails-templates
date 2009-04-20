use_github = yes? 'Host repository on GitHub?'

application_name_human = ask 'Enter a human-readable application name'
application_name_machine = ask 'Enter a machine-useable application name'

production_user = ask 'Production server username:'
production_domain = ask 'Production server domain:'
production_sub_domain = ask 'Production server sub-domain:'
production_host = ask 'Production server host:'

production_db_user = ask 'Production database login'
production_db_pass = ask 'Production database password'

setup_staging = yes? 'Setup staging server?'

if setup_staging
  staging_user = ask 'Staging server username:'
  staging_domain = ask 'Staging server domain:'
  staging_sub_domain = ask 'Staging server sub-domain:'
  staging_host = ask 'Staging server host:'

  staging_db_user = ask 'Staging database login'
  staging_db_pass = ask 'Staging database password'
end



capify!
freeze!



# Set up git repository
  git :init



# Delete unnecessary files
  run 'rm README'
  run 'rm public/index.html'
  run 'rm public/favicon.ico'
  #run 'rm public/robots.txt'
  run 'rm -f public/javascripts/*'



# Copy database.yml for distribution use
  run 'cp config/database.yml config/database.yml.example'



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
set :application, '#{application_name_machine}'
set :domain, '#{staging_domain}'
set :sub_domain, '#{staging_sub_domain}'
set :host, '#{staging_host}'
set :deploy_to, "/home/\#{user}/public_html/\#{domain}/\#{sub_domain}"
set :deploy_via, :remote_cache

# For migrations
set :rails_env, 'staging'

# Deploy details
set :scm, :git
#set :repository, "ssh://\#{user}@\#{host}/home/\#{user}/repositories/\#{domain}/\#{sub_domain}/.git" # CHOOSE
#set :repository, "git@github.com:\#{user}/\#{application}.git" # CHOOSE
set :branch, 'master'
set :git_shallow_clone, 1
set :scm_verbose, true
}
end


  file 'config/deploy/production.rb',
%Q{# Who are we?
set :user, '#{production_user}'

# Project hosting details
set :application, '#{application_name_machine}'
set :domain, '#{production_domain}'
set :sub_domain, '#{production_sub_domain}'
set :host, '#{production_host}'
set :deploy_to, "/home/\#{user}/public_html/\#{domain}/\#{sub_domain}"
set :deploy_via, :remote_cache

# For migrations
set :rails_env, 'production'

# Deploy details
set :scm, :git
#set :repository, "ssh://\#{user}@\#{host}/home/\#{user}/repositories/\#{domain}/\#{sub_domain}/.git" # CHOOSE
#set :repository, "git@github.com:\#{user}/\#{application}.git" # CHOOSE
set :branch, 'master'
set :git_shallow_clone, 1
set :scm_verbose, true
}



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
  database: #{application_name_machine}_production
}
  database_yaml += %Q{
staging:
  <<: *remote_defaults
  database: #{application_name_machine}_staging
} if setup_staging
  file 'config/database.yml', database_yaml



# Set up .gitignore files
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



# Place an empty .gitignore in empty directories
  run %{find . -type d -empty | grep -v 'vendor' | grep -v '.git' | grep -v 'tmp' | xargs -I xxx touch xxx/.gitignore}



# Add gems
  #gem 'binarylogic-authlogic', :lib => 'authlogic', :source => 'http://gems.github.com'
  #rake 'gems:install'



# Add plugins
  #plugin name, options = {}



# Set up sessions, RSpec, user model, OpenID, etc and run migrations
  rake 'db:create'
  rake 'db:sessions:create'
  #generate :scaffold, 'person', 'first_name:string', 'last_name:string', 'born_at:datetime'
  rake 'db:migrate'



# Configure home page
  #route "map.root :controller => 'people'"



# Initialize submodules
  #git :submodule => 'init'



# Commit all work so far to the repository
  git :add => '.'
  git :commit => "-m 'Initial commit'"

