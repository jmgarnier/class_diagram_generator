class Project < Base
  belongs_to :category

  has_many :money_elements, :class_name => "Element", :conditions => "1 = 1"
  has_many :incomplete_elements, :class_name => "Element", :conditions => "1 = 1"
  has_many :unexpired_elements, :class_name => "Element", :conditions => "1 = 1"
  has_many :completed_elements, :class_name => "Element", :conditions => "1 = 1"
  has_many :expired_elements, :class_name => "Element", :conditions => "1 = 1"

end