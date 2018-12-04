require 'colorize'

module SafePusher
  class RSpecRunner
    def initialize
      @specs_to_execute = []
    end

    def call
      return 1 if list_files_to_execute == 1

      run_specs
    end

    private

    attr_reader :specs_to_execute

    def list_files_to_execute
      modified_files.map do |f|
        return 1 if analyze_file(f) == 1
      end.compact
    end

    def modified_files
      `git whatchanged --name-only --pretty="" origin..HEAD`.split("\n").uniq
    end

    def analyze_file(f)
      if f.match(%r{#{SafePusher.configuration.app_base_directory}\/.*\.rb$}) &&
         !f.match(files_to_skip)
        puts "#{f} has been modified, searching for specs..."

        spec_path = f.gsub(
          SafePusher.configuration.app_base_directory,
          'spec/',
        ).gsub('.rb', '_spec.rb')

        if File.exist?(spec_path)
          puts "Spec found for #{f}, putting #{spec_path}"\
               ' in the list of specs to run'
          specs_to_execute << spec_path
        else
          return create_new_spec(spec_path, f)
        end
      elsif !specs_to_execute.include?(f) && !f.match(files_to_skip)
        puts "#{f} modified, putting it in the list of specs to run"
        specs_to_execute << f
      end
    end

    def files_to_skip
      Regexp.new(
        SafePusher.configuration.files_to_skip.join('|').gsub('/', '\/'),
      )
    end

    def run_specs
      if specs_to_execute.empty?
        puts 'no spec analyzed, passing to the next step'.green
        return 0
      end

      system("bin/rspec #{specs_to_execute.join(' ')}")

      exit_status = $CHILD_STATUS.exitstatus

      if exit_status != 0
        puts 'Oops, a spec seems to be red or empty, '\
             'be sure to complete it before you push'.red
      else
        puts 'Every spec operational, '\
             'passing to the next step!'.green
      end

      exit_status
    end

    def create_new_spec(spec_path, file_matched)
      puts "no spec found for file #{file_matched},"\
           " would you like to add #{spec_path}? (Yn)"
      result = STDIN.gets.chomp

      if result.casecmp('n') == 0
        puts 'Alright, skipping the test for now!'
        return 0
      else
        File.open(spec_path, 'w') do |file|
          file.write(template(spec_path))
        end
        warn 'spec to write!'.red
        return 1
      end
    end

    def template(spec_path)
      class_name =
        File.basename(spec_path)
          .gsub('_spec.rb', '')
          .split('_')
          .map(&:capitalize)
          .join
      "require \'rails_helper\'\n\nRSpec.describe #{class_name} do\nend"
    end
  end
end
