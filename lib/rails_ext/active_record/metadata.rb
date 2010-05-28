module ActiveRecord

  class Metadata

    ASSOCIATION_TYPES = %w[belongs_to has_one has_many has_through]

    def initialize
      @association_graphs = {}
      ASSOCIATION_TYPES.each { |type|
        @association_graphs[type] = Graph.new
      }
    end

    def add_association(diagram_association)
      @association_graphs[diagram_association.type].
              add_edge(diagram_association.from_class_name, diagram_association.to_class_name, diagram_association.name)
    end

    def include_link_for_association?(diagram_association)
      @association_graphs[diagram_association.type].
              has_edge_between?(diagram_association.from_class_name, diagram_association.to_class_name)
    end

    def agregated_label_for_association(diagram_association)
      @association_graphs[diagram_association.type].
              label_for_edge(diagram_association.from_class_name, diagram_association.to_class_name)
    end

    class Association

      def initialize(from_class, active_record_association_reflection)
        @active_record_association_reflection = active_record_association_reflection
        @from_class_name = from_class.name
        @to_class_name = get_to_class_name
        @name = get_association_name
        @type, @cardinality = get_type_and_cardinality
      end

      attr_reader :active_record_association_reflection, :from_class_name, :name, :type, :cardinality, :to_class_name

      private

      def yuml_me_label
        agregated_label = ClassDiagramGenerator.associations_metadata.agregated_label_for_association(self)
        "[#{@from_class_name}]-#{@type}#{agregated_label} >#{@cardinality}[#{@to_class_name}]"
      end

      # TODO find better name
      def get_to_class_name
        if (@active_record_association_reflection.class_name.respond_to? 'underscore')
          @active_record_association_reflection.class_name.pluralize.singularize.camelize
        else
          @active_record_association_reflection.class_name
        end
      end

      def get_association_name
        @to_class_name == @active_record_association_reflection.name.to_s.singularize.camelize ? '' : @active_record_association_reflection.name.to_s
      end

      def get_type_and_cardinality
        @habtm ||= []
        association_macro_type = @active_record_association_reflection.macro.to_s

        type = if association_macro_type == 'belongs_to'
          cardinality = ""
          "belongs_to"
        elsif association_macro_type == 'has_one'
          cardinality = "1"
          "has_one"
        elsif association_macro_type == 'has_many' && (! @active_record_association_reflection.options[:through])
          cardinality = "*"
          "has_many"
        else # habtm or has_many, :through
          next if @habtm.include? [@active_record_association_reflection.class_name, @from_class_name, @name]
          @habtm << [@from_class_name, @active_record_association_reflection.class_name, @name]
          cardinality = "*"
          "has_through"
        end
        return type, cardinality
      end

    end

    class Graph
      def initialize
        @edges = {}
        @edge_labels = {}
      end

      # attr_reader :edges
      def add_edge(from, to, label="")
        @edges[from] ||= []
        @edges[from] << to

        add_edge_label(from, to, label)
      end

      def add_edge_label(from, to, label)
        key = edge_label_key(from, to)
        @edge_labels[key] ||= []
        @edge_labels[key] << humanize_label(label, to) unless label.blank?
      end

      private :add_edge_label

      def edge_label_key(from, to)
        "#{from}->#{to}"
      end

      private :edge_label_key

      def humanize_label(label, to)
        label.gsub("_" + to.downcase.pluralize, "").gsub("_", " ")
      end

      private :humanize_label

      def has_edge_between?(from, to)
        @edges.has_key?(from) && @edges[from].include?(to)
      end

      def label_for_edge(from, to)
        key = edge_label_key(from, to)
        return "" unless @edge_labels.has_key? key

        @edge_labels[key].sort.join(" / ").append_char_at_the_beginning_if_not_blank(' ')
      end

    end
  end
  
end