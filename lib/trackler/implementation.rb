require 'pathname'
require_relative 'file_bundle'

module Trackler
  # Implementation is a language-specific implementation of an exercise.
  class Implementation
    IGNORE_PATTERNS = [
      "\/HINTS\.md$",
      "\/\.$",
      "/\.meta/"
    ]

    extend Forwardable
    def_delegators :@problem, :name, :blurb, :description, :source_markdown, :slug

    attr_reader :track, :problem
    attr_writer :files
    def initialize(track, problem)
      @track = track
      @problem = problem
    end

    def dir
      @dir ||= track.dir.join(exercise_dir)
    end

    def exists?
      File.exist?(dir)
    end

    def files
      @files ||= Hash[file_bundle.paths.map {|path|
        [path.relative_path_from(dir).to_s, File.read(path)]
      }].merge("README.md" => readme)
    end

    def zip
      @zip ||= file_bundle.zip do |io|
        io.put_next_entry('README.md')
        io.print readme
      end
    end

    def readme
      @readme ||= assemble_readme
    end

    def git_url
      [track.repository, "tree/master", exercise_dir].join("/")
    end

    private

    def exercise_dir
      if File.exist?(track.dir.join('exercises'))
        File.join('exercises', slug)
      else
        slug
      end
    end

    def file_bundle
      @file_bundle ||= FileBundle.new(dir, regexes_to_ignore)
    end

    def regexes_to_ignore
      (IGNORE_PATTERNS + [track.ignore_pattern]).map do |pattern|
        Regexp.new(pattern, Regexp::IGNORECASE)
      end
    end

    def assemble_readme
      <<-README
#{description_markdown}

#{incomplete_solutions_section}
README
    end

    def description_markdown
      <<-MARKDOWN.chomp
# #{name}

#{blurb}

#{body}

#{source_markdown}
MARKDOWN
    end

    def body
      [
        description,
        hints,
      ].reject(&:empty?).join("\n").strip
    end

    def hints
      [
        hints_file_contents,
        track.hints
      ].reject(&:empty?).join("\n").strip
    end

    def incomplete_solutions_section
      <<-README
## Submitting Incomplete Problems
It's possible to submit an incomplete solution so you can see how others have completed the exercise.
      README
    end

    def hints_file_contents
      hints_file = File.join(dir, 'HINTS.md')
      File.exist?(hints_file) ? File.read(hints_file) : ''
    end
  end
end
