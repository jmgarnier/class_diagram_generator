class Friendship < ActiveRecord::Base
  belongs_to :from, :class_name => 'User'
  belongs_to :to, :class_name => 'User'
  has_one :child, :class_name => 'Friendship', :foreign_key => 'parent_id', :dependent => :delete
  belongs_to :parent, :class_name => 'Friendship'
  belongs_to :initiated_by, :class_name => 'User'
end