require 'thor'
require 'cfoo'
require 'fileutils'

module Hygroscope
  def self.cfoo_process(path)
    files = Dir.glob(File.join(path, '*.{yml,yaml}'))
    cfoo = Cfoo::Factory.new(STDOUT, STDERR).cfoo

    # cfoo's file parser assumes relative paths
    Dir.chdir('/') do
      cfoo.process(*files)
    end
  end
end
