ENV['EXECJS_RUNTIME'] = 'RubyRacer'

require 'eslint-rails'

namespace :eslint do

  desc %{Run ESLint against the specified JavaScript file and report warnings (default is 'application')}
  task :run, [:filename] => :environment do |_, args|
    warnings = ESLintRails::Runner.new(args[:filename]).run

    if warnings.empty?
      puts 'All good! :)'.green
      exit 0
    else
      formatter = ESLintRails::TextFormatter.new(warnings)
      formatter.format
      exit 1
    end
  end

  desc 'Run ESlint against each JavaScript file for a specified directory and report warnings'
  task :run_dir, [:directory] => :environment do |_, args|
    directory_path = Dir["app/assets"][0] # if a directory is not set as an argument, grab all the JavaScript files in the 'assets' directory

    if args[:directory] # if a directory is provided, get its path
      directory_path = Dir["app/assets/**/#{args[:directory]}"][0]
    end

    full_paths = Dir["#{directory_path}/**/*.js*"]
    file_paths = full_paths.map do |path|
      path.sub!(/^app\/assets\//, "") # strip 'app/assets/' from the path
    end

    # exclude files from linting, e.g. rake eslint:run_dir ignore=application.js
    excluded_files = ENV['ignore'] ? ENV['ignore'].split(",") : []
    file_paths = file_paths.reject do |path|
      excluded_files.include? path
    end

    file_paths.each do |filename|
      warnings = ESLintRails::Runner.new(filename).run # run ESLint on every file for the directory
      success = "\u2713"
      failure = "\u2717"
      if warnings.empty?
        print success.encode('utf-8').green, " ", filename.blue, "\n"
      else
        print failure.encode('utf-8').red, " ", filename.blue, "\n"
        formatter = ESLintRails::TextFormatter.new(warnings)
        formatter.format
        break if ENV['breakOnError']
      end
    end
  end

  desc 'Print the current configuration file (Uses local config/eslint.json if it exists; uses default config/eslint.json if it does not; optionally force default by passing a parameter)'
  task :print_config, [:force_default] => :environment do |_, args|
    puts ESLintRails::Config.read(force_default: args[:force_default])
  end
end
