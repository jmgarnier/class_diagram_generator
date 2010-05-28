class User < ActiveRecord::Base

  with_options :class_name => "Project", :foreign_key => 'manager_id' do |as_manager|
    as_manager.has_many :managed_projects,     :dependent => :destroy
  end

  has_many :friendships, :foreign_key => "from_id", :dependent => :destroy
  has_many :friends, :through => :friendships, :source => :to, :order => "friendships.created_at DESC"

  def business_method; end
  
end