set :application, 'cpa_invoicer'
set :repo_url, 'https://github.com/rorymckinley/cpa_invoicer.git'

ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :deploy_to, '/var/www/railsapp'
# set :scm, :git

# set :format, :pretty
# set :log_level, :debug
# set :pty, true

set :linked_files, %w{config/database.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
set :keep_releases, 5

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute "cd #{release_path} && if [ -e tmp/pids/unicorn.pid ]; then old_pid=$(cat tmp/pids/unicorn.pid); kill -s USR2 $old_pid && kill -s QUIT $old_pid && touch #{release_path}/blah.di.blah; else bundle exec unicorn_rails -E production -c config/unicorn.rb -D; fi"
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  after :finishing, 'deploy:cleanup'

end
