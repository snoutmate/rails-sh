require 'rake'
require 'stringio'

module Rails
  module Sh
    module Rake
      extend Forkable

      class << self
        def init
          $stdout = StringIO.new

          before_fork do
            ActiveRecord::Base.remove_connection if defined?(ActiveRecord::Base)
          end
          after_fork do
            ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
          end

	  ::Rake::TaskManager.record_task_metadata = true # must call before Rake.application.init
          ::Rake.application.options.show_tasks = :tasks

          ::Rake.application = ::Rake::Application.new
          ::Rake.application.init
          ::Rake.application.load_rakefile
          ::Rake.application[:environment].invoke
        ensure
          $stdout = STDOUT
        end

        def _invoke(line)
          line ||= 'default'
          name, *args = line.split(/\s+/)
          args.each do |arg|
            env, value = arg.split('=')
            next unless env && !env.empty? && value && !value.empty?
            ENV[env] = value
          end
          ::Rake.application[name].invoke
        end

        def task_names
          ::Rake.application.tasks.map{|t| t.name}
        end
      end
    end
  end
end
