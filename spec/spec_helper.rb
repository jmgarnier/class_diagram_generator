require 'rubygems'

require 'spec'
require 'sqlite3'
require 'active_record'
require 'action_controller'

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database  => ':memory:'
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :projects, :force => true do |t|
    t.column :name, :string
  end

  create_table :users, :force => true do |t|
    t.column :first_name, :string
    t.column :last_name, :string
  end
end

require File.dirname(__FILE__) + '/../lib/class_diagram_generator'

Dir[File.dirname(__FILE__) + "/app/models/*"].each do |path|
  Object.autoload(File.basename(path, ".rb").classify.to_sym, path)
end

class ApplicationController < ActionController::Base
end

Dir[File.dirname(__FILE__) + "/app/controllers/*"].each do |path|
  Object.autoload(File.basename(path, ".rb").classify.to_sym, path)
end