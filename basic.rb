# Delete unnecessary files
  run 'rm README'
  run 'rm public/index.html'
  run 'rm public/favicon.ico'
  #run 'rm public/robots.txt'
  run 'rm -f public/javascripts/*'

# @todo: Download JQuery
# @todo: Prep staging and production servers
# @todo: Confirgure capistrano

# Set up git repository
  git :init

# Copy database.yml for distribution use
  run 'cp config/database.yml config/database.yml.example'

# Set up .gitignore files
  run 'touch tmp/.gitignore log/.gitignore vendor/.gitignore'
  run %{find . -type d -empty | grep -v 'vendor' | grep -v '.git' | grep -v 'tmp' | xargs -I xxx touch xxx/.gitignore}
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

# Set up sessions, RSpec, user model, OpenID, etc, and run migrations
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

# Success!
  puts 'SUCCESS!'
