require 'thor'
require 'fileutils'
require 'tempfile'
require 'yaml'
require 'aws-sdk'

require_relative 'hygroscope/cli'
require_relative 'hygroscope/cloudformation'
require_relative 'hygroscope/paramset'
