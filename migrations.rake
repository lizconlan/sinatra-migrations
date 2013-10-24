task :environment do
  env = ENV["RACK_ENV"] ? ENV["RACK_ENV"] : "development"
  ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml'))[env])
  p "** #{env}"
end

namespace :db do
  def connect(conf)
    if conf["adapter"] == 'postgresql'
      ActiveRecord::Base.establish_connection(conf.merge('database' => 'postgres'))
    else
      ActiveRecord::Base.establish_connection(conf.merge('database' => nil))
    end
  end
  
  desc "Create the database defined in config/database.yml for the current RACK_ENV"
  task :create do
    env = ENV["RACK_ENV"] ? ENV["RACK_ENV"] : "development"
    config = YAML::load(File.open('config/database.yml'))[env]
    connect(config)
    ActiveRecord::Base.connection.create_database(config['database'])
  end
  
  namespace :create do
    desc "Create all the local databases defined in config/database.yml"
    task :all do
      YAML::load(File.open('config/database.yml')).each_value do |config|
        next unless config['database']
        unless @config
          connect(config)
          @config = 1
        end
        ActiveRecord::Base.connection.create_database(config['database'])
      end
    end
  end
  
  desc "Drops the database for the current RACK_ENV"
  task :drop do
    env = ENV["RACK_ENV"] ? ENV["RACK_ENV"] : "development"
    config = YAML::load(File.open('config/database.yml'))[env]
    connect(config)
    ActiveRecord::Base.connection.drop_database config['database']
  end
  
  namespace :drop do
    desc "Drops all the local databases defined in config/database.yml"
    task :all do
      YAML::load(File.open('config/database.yml')).each_value do |config|
        next unless config['database']
        unless @config
          connect(config)
          @config = 1
        end
        ActiveRecord::Base.connection.drop_database config['database']
      end
    end
  end
  
  desc "Migrate the database through scripts in db/migrate"
  task(:migrate => :environment) do
    ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end

  namespace :migrate do
    desc 'Runs the "down" for a given migration VERSION'
    task(:down => :environment) do
      ActiveRecord::Migrator.down('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
    
    desc 'Runs the "up" for a given migration VERSION'
    task(:up => :environment) do
      ActiveRecord::Migrator.up('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
    
    desc "Rollbacks the database one migration and re migrate up"
    task(:redo => :environment) do
      ActiveRecord::Migrator.rollback('db/migrate', 1 )
      ActiveRecord::Migrator.up('db/migrate', nil )
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
  end
  
  namespace :schema do
    task :dump => :environment do
      require 'active_record/schema_dumper'
      File.open(ENV['SCHEMA'] || "db/schema.rb", "w") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end
  end
end