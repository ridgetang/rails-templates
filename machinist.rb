# Machinist generates example objects for use in specs and test suites.
# It's similar to Factory Girl, although it takes a slightly different
# approach.  For more information, see:
#
#   http://github.com/notahat/machinist/tree/master
#
# This application template sets up both RSpec and Test::Unit.  You'll
# probably want to delete one or the other.
#
# Note that the gsub_file patterns may need a little tweaking for other
# versions of Rails.  These patterns were tested with Rails 2.3.2.

# Declare a dependency on RSpec.
gem('rspec', :lib => false, :version => '>= 1.2.4')
gem('rspec-rails', :lib => false, :version => '>= 1.2.4')

# Declare dependencies on Machinist and Faker.
gem('faker', :version => '>= 0.3.1')
gem('notahat-machinist', :version => '>= 0.3.1', :lib => 'machinist',
    :source => 'http://gems.github.com')

# Install our gems.
rake 'gems:install', :sudo => true

# Set up RSpec.
generate 'rspec'

# Make sure we run both specs and tests when running 'rake'.
append_file 'Rakefile', "\ntask :default => [:spec, :test]"

# Add blueprint.rb file for use with machinist.
file 'spec/blueprints.rb', <<"EOD"
# This file offers a convenient alternative to fixtures.  For instructions,
# see http://github.com/notahat/machinist/tree/master .

#Sham.name  { Faker::Name.name }
#Sham.email { Faker::Internet.email }
#
#User.blueprint do
#  name
#  email
#end
#
# In a spec, you can call User.make to create an example object:
#   User.make(:name => "George") # :email chosen automatically.
EOD

# Hook machinist up to RSpec.
log 'modifying', 'spec/spec_helper.rb'
gsub_file('spec/spec_helper.rb', %r{^require 'spec/rails'}) do |match|
  match + "\nrequire File.join(File.dirname(__FILE__), 'blueprints')"
end
gsub_file('spec/spec_helper.rb', %r{^Spec::Runner.configure .*}) do |match|
  match + "\n  config.before(:each) { Sham.reset }"
end

# Optional: Hook machinist up to Test::Unit.
log 'modifying', 'test/test_helper.rb'
gsub_file('test/test_helper.rb', %r{^require 'test_help'}) do |match|
  match + "\nrequire File.join(File.dirname(__FILE__), '../spec/blueprints')"
end
gsub_file('test/test_helper.rb', %r{^  \# Add more helper .*}) do |match|
  match + "\n  setup { Sham.reset }"
end
