# frozen_string_literal: true

require 'pathname'

module FileFixtureSupport
  # Adds simple access to sample files called file fixtures.
  #
  # File fixtures are represented as +Pathname+ objects.
  # This makes it easy to extract specific information:
  #
  #   file_fixture("example.txt").read # get the file's content
  #   file_fixture("example.mp3").size # get the file size

  def self.included(base)
    base.extend(ClassMethods)
    base.file_fixture_path = RSpec.configuration.file_fixture_path
  end

  module ClassMethods
    def inherited(subclass)
      super
      subclass.file_fixture_path = RSpec.configuration.file_fixture_path
    end

    def file_fixture_path=(value)
      @file_fixture_path = value
    end

    def file_fixture_path
      @file_fixture_path
    end
  end

  def file_fixture_path
    self.class.file_fixture_path
  end

  def file_fixture(fixture_name)
    path = Pathname.new(File.join(file_fixture_path, fixture_name))

    if path.exist?
      path
    else
      msg = "the directory '%<dir_name>s' does not contain a file named '%<file_name>s'"
      raise ArgumentError, format(msg, dir_name: file_fixture_path, file_name: fixture_name)
    end
  end
end
