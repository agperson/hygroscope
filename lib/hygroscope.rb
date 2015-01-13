require 'thor'
require 'cfoo'
require 'fileutils'
require 'tempfile'
require 'yaml'
require 'aws-sdk'

module Hygroscope
  def self.process_to_file(path)
    file = Tempfile.new(['hygroscope-', '.json'])
    file.write(self.process(path))
    file.close

    at_exit { file.unlink }

    file.path
  end

  def self.process(path)
    out = StringIO.new

    files = Dir.glob(File.join(path, '*.{yml,yaml}'))
    cfoo = Cfoo::Factory.new(out, STDERR).cfoo

    # cfoo's file parser assumes relative paths
    Dir.chdir('/') do
      cfoo.process(*files)
    end

    out.string
  end
end
