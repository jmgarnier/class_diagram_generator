class Class

  def hierarchy
    (superclass && superclass != Object ? superclass.hierarchy : []) << self
  end

  def to_yumlme_dsl(options)
    return class_name_to_yuml_me unless options.public_methods
    return class_name_to_yuml_me if is_a_rails_base_class?

    "#{self.name}#{public_methods_separated_by_semi_column}".to_yuml_me_class
  end

  def class_name_to_yuml_me
    "#{self.name}".to_yuml_me_class
  end

  def public_methods_separated_by_semi_column
    # If the optional parameter is not <code>false</code>, the methods of
    # any ancestors are included.
    "|" + self.public_instance_methods(false).sort.map{|m| "+#{m}"}.join(';')
  end

  def is_a_rails_base_class?
    self == ActiveRecord::Base || self == ActionController::Base
  end
  
end