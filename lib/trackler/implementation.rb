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

    attr_reader :track, :problem
    attr_writer :files
    def initialize(track, problem)
      @track = track
      @problem = problem
    end

    def exists?
      File.exist?(dir)
    end

    def dir
      @dir ||= track.dir.join(exercise_dir)
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
      @readme ||= ReadmeGenerator.new(implementation: self, track: track, problem: problem).to_s
    end

    def git_url
      [track.repository, "tree/master", exercise_dir].join("/")
    end

    def hints
      hints_file = File.join(dir, 'HINTS.md')
      File.exist?(hints_file) ? File.read(hints_file) : ''
    end

    private

    def exercise_dir
      if File.exist?(track.dir.join('exercises'))
        File.join('exercises', problem.slug)
      else
        problem.slug
      end
    end

    def file_bundle
      @file_bundle ||= FileBundle.new(dir, regexes_to_ignore)
    end

    def regexes_to_ignore
      (IGNORE_PATTERNS + [@track.ignore_pattern]).map do |pattern|
        Regexp.new(pattern, Regexp::IGNORECASE)
      end
    end

    # Generates the Readme.md for the implementation
    class ReadmeGenerator
      attr_reader :implementation, :track, :problem

      def initialize(implementation:, track:, problem:)
        @implementation = implementation
        @track = track
        @problem = problem
      end

      def to_s
        <<-README
# #{problem.name}

#{problem.blurb}

#{body}

#{problem.source_markdown}

#{incomplete_solutions_section}
README
      end

      def body
        [
          problem.description,
          implementation.hints,
          track.hints,
        ].reject(&:empty?).join("\n").strip
      end

      def incomplete_solutions_section
        <<-README
## Submitting Incomplete Problems
It's possible to submit an incomplete solution so you can see how others have completed the exercise.
        README
      end
    end
  end
end
