class ActiveRecord::Base

  class << self
    def to_yumlme_dsl(options)
      @@options = options

      public_methods = if options.public_methods
        business_methods_separated_by_semi_column
      else
        ""
      end
      "#{self.name}#{attributes_separated_by_semi_column}#{public_methods}".to_yuml_me_class + associations_to_yumlme_dsl
    end

    private

    def attributes_separated_by_semi_column
      return "" unless @@options.attributes
      "|#{self.content_columns.map(&:name).join(';')}"
    end

    def business_methods_separated_by_semi_column
      business_logic_methods = self.public_instance_methods(false).
              reject{|m| m.start_with?("validate_associated_records_for_") ||
              m.ends_with?("_ids") ||
              m.include?("=") ||
              m.starts_with?("create_") ||
              m.starts_with?("build_")  ||
              m.starts_with?("autosave_associated_records_for_") ||
              m.starts_with?("has_many_dependent_destroy_for_") ||
              %w(to_param to_s to_xml tz).include?(m) }

      # Remove associations getter & setters
      association_names = self.reflect_on_all_associations.map{|a| a.name.to_s }
      business_logic_methods = business_logic_methods.
              reject{|m| association_names.include?(m) || association_names.include?("#{m}=")}

      "|" + business_logic_methods.sort.map{|m| "+#{m}"}.join(';')
    end

    def associations_to_yumlme_dsl
      return "" unless @@options.associations

      associations_list = []
      self.reflect_on_all_associations.map do |association_reflection|
        association = ActiveRecord::Metadata::Association.new(self, association_reflection)

        next unless is_included_in_diagram_classes?(association.to_class_name)
        next if is_connected_to_a_class_not_included_in_diagram_through?(association.active_record_association_reflection)

        puts "#{association.from_class_name} - #{association.name} > #{association.to_class_name}" if @@options.debugging
        unless ClassDiagramGenerator.associations_metadata.include_link_for_association?(association)
          puts "adding association btw #{association.from_class_name} and #{association.to_class_name}\n\n" if @@options.debugging
          associations_list << association
        end

        ClassDiagramGenerator.associations_metadata.add_association association
        puts "Adding edge #{association.from_class_name} #{association.type} -> #{association.to_class_name}" if @@options.debugging
      end

      associations_list.map(&:yuml_me_label).join(",").append_char_at_the_beginning_if_not_blank(',')
      # puts "DSL for class #{self.name} = #{associations_dsl}\n\n" if @@options.debugging
    end

    def is_included_in_diagram_classes?(association_class_name)
      @@options.classes.map(&:name).include?(association_class_name)
    end

    def is_connected_to_a_class_not_included_in_diagram_through?(association)
      association.source_reflection && association.source_reflection.active_record && !is_included_in_diagram_classes?(association.source_reflection.active_record.class_name)
    end

  end

end