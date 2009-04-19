lib_name = ask 'What do you want to call the shiny library?'
do_something = yes? 'Freeze rails gems?'



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
%q{require 'capistrano/ext/multistage'

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

set :use_sudo, false

set :stages, %w(staging production)
set :default_stage, 'staging'

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
    send run_method, "cd #{current_path} && #{mongrel_rails} cluster::start --config #{mongrel_cluster_config}"
  end

  desc 'Stop server'
  task :stop do
    send run_method, "cd #{current_path} && #{mongrel_rails} cluster::stop --config #{mongrel_cluster_config}"
  end

  desc 'Restart server'
  task :restart do
    #send run_method, "cd #{deploy_to}/#{current_dir} && #{mongrel_rails} cluster::restart --config #{mongrel_cluster_config}"
    run "touch #{current_path}/tmp/restart.txt"
  end

  desc 'Run this after every successful deployment'
  task :after_default do
    cleanup
  end
end

task :after_update_code do
  run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
end

namespace :db do
  desc 'Create database password in shared path'
  task :password do
    set :db_password, Proc.new { Capistrano::CLI.password_prompt 'Remote database password: ' }
    run "mkdir -p #{shared_path}/config"
    put db_password, "#{shared_path}/config/dbpassword"
  end
end
}


  file 'config/deploy/staging.rb',
%q{# Who are we?
set :user, 'randombydesign' # PROMPT

# Project hosting details
set :application, 'IsItTheWeekendYet' # PROMPT
set :domain, 'randombydesign.com' # PROMPT
set :sub_domain, 'weekend' # PROMPT
set :host, 'rbd.dreamhost.com' # PROMPT
set :deploy_to, "/home/#{user}/public_html/#{domain}/#{sub_domain}"
set :deploy_via, :remote_cache

# For migrations
set :rails_env, 'staging'

# Deploy details
set :scm, :git
#set :repository, "ssh://#{user}@#{host}/home/#{user}/repositories/#{domain}/#{sub_domain}/.git" # CHOOSE
#set :repository, "git@github.com:#{user}/#{application}.git" # CHOOSE
set :branch, 'master'
set :git_shallow_clone, 1
set :scm_verbose, true
}


  file 'config/deploy/production.rb',
%q{# Who are we?
set :user, 'randombydesign' # PROMPT

# Project hosting details
set :application, 'IsItTheWeekendYet' # PROMPT
set :domain, 'isittheweekendyet.com' # PROMPT
set :sub_domain, 'www' # PROMPT
set :host, 'rbd.dreamhost.com' # PROMPT
set :deploy_to, "/home/#{user}/public_html/#{domain}/#{sub_domain}"
set :deploy_via, :remote_cache

# For migrations
set :rails_env, 'production'

# Deploy details
set :scm, :git
#set :repository, "ssh://#{user}@#{host}/home/#{user}/repositories/#{domain}/#{sub_domain}/.git" # CHOOSE
#set :repository, "git@github.com:#{user}/#{application}.git" # CHOOSE
set :branch, 'master'
set :git_shallow_clone, 1
set :scm_verbose, true
}



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
  gem 'authlogic'



# Add plugins
  #plugin name, options = {}



# Set up sessions, RSpec, user model, OpenID, etc and run migrations
  rake 'db:sessions:create'
  rake 'db:migrate'



# Set up additional resources
  #generate :scaffold, 'person', 'first_name:string', 'last_name:string', 'born_at:datetime'
  #rake 'db:migrate'



# Configure home page
  #route "map.root :controller => 'people'"



# Commit all work so far to the repository
  git :add => '-u'
  git :add => '.'
  git :commit => "-m 'Initial commit'"

