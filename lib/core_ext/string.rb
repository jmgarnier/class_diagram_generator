class String
  def to_yuml_me_class
    "[#{self}]"
  end

  def append_char_at_the_beginning_if_not_blank(char)
    self.blank? ? '' : "#{char}#{self}"
  end

end