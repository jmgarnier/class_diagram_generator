# TODO Make it look like more ruby
(Dir[File.dirname(__FILE__) + "/core_ext/*"] + Dir[File.dirname(__FILE__) + "/rails_ext/active_record/*"]).each do |path|
  require path
end

class ClassDiagramGenerator

  cattr_accessor :associations_metadata

  def initialize
    @style = "nofunky"
    @note= ""
    @classes = []
    @options = ClassDiagramGenerator::Options.new
    ClassDiagramGenerator.associations_metadata = ActiveRecord::Metadata.new
  end

  # TODO Diagram style ?

  OPTIONS_LIST = %w[attributes public_methods inheritance associations association_types debugging]
  OPTIONS_LIST.each do |option|
    define_method("show_#{option}") do
      eval "@options.#{option} = true"
      self
    end

    define_method("hide_#{option}") do
      eval "@options.#{option} = false"
      self
    end
  end

  class Options
    OPTIONS_LIST.each do |option|
      attr_accessor option.to_sym
    end

    attr_accessor :classes
  end

  def with_note(note)
    @note = "[note: #{note}]"
    self
  end

  # Classes & introspection
  def with_classes (*klasses)
    @classes << klasses
    @classes = @classes.flatten
    self
  end

  def with_all_model_classes(pattern="app/models/**/*.rb", except_files=[])
    files = Dir.glob(pattern) - except_files
    # files += Dir.glob("vendor/plugins/**/app/models/*.rb") if @options.plugins_models

    files.each do |file|
      model_name = File.basename(file, '.rb').camelize
      next if /_related/i =~ model_name
      @classes <<  get_model_class(model_name)
    end
    self
  end

  def get_model_class(model_name)
    begin
      model_name.constantize
    rescue LoadError
      STDERR.print "\t#{model_name} raised LoadError.\n"
      oldlen = model_path.length
      model_path.gsub!(/.*[\/\\]/, '')
      model_name = model_path.camelize
      if oldlen > model_path.length
        retry
      end
      STDERR.print "\tDone trying to remove slashes, skipping this model.\n"
    rescue NameError
      STDERR.print "\t#{model_name} raised NameError, skipping this model.\n"
    end
  end
  private :get_model_class

  def with_all_controller_classes(pattern="app/controllers/**/*_controller.rb", except_files=[])
    begin
      files = Dir.glob(pattern) - except_files
      files.each { |file| @classes << get_controller_class(file) }
    rescue LoadError
      raise
    end
    self
  end

  def get_controller_class(file)
    model = file.sub(/^.*app\/controllers\//, '').sub(/\.rb$/, '').camelize
    parts = model.split('::')
    begin
      parts.inject(Object) {|klass, part| klass.const_get(part) }
    rescue LoadError
      Object.const_get(parts.last)
    end
  end

  private :get_controller_class

  # TODO Is it possible to move the generation code in another class?

  def to_yumlme_dsl
    # FIXME tmp FIX for modules
    # @classes -= [ActsAsRateable, AuthenticatedBase, Geocodeable, HasStatus, XmasProjectMethods]

    @options.classes = @classes
    # puts @classes if @options.debugging

    @yumlme_dsl = @note + @classes.map do |klass|
      unless @options.inheritance
        klass.to_yumlme_dsl(@options)
      else
        create_yuml_dsl_for_class_hierarchy(klass)
      end
    end.flatten.uniq.join(",")
  end

  def create_yuml_dsl_for_class_hierarchy(klass)
    hierarchy = klass.hierarchy

    hierarchy.delete(ActiveRecord::Base)

    # FIXME write a test for this line
    return klass.to_yumlme_dsl(@options) if hierarchy.size == 1

    # TODO Make it look like ruby
    dsl = []
    last_item_index = hierarchy.size - 1
    hierarchy.each_with_index do |klass, index|
      if index < last_item_index
        super_class_dsl = klass.to_yumlme_dsl(@options)
        child_class_dsl = hierarchy[index+1].to_yumlme_dsl(@options)
        dsl << "#{super_class_dsl}^-#{child_class_dsl}"
      end
    end
    dsl
  end

  private :create_yuml_dsl_for_class_hierarchy

  def to_png(file, diagram_options="")
    output(file, "", diagram_options)
  end

# http://yuml.me/diagram/class/[Customer]+->[Order].pdf
  def to_pdf(file, diagram_options="")
    self.output(file, ".pdf", diagram_options)
  end

#  def to_url( options, data, type ) #:nodoc:
#    opts = options.clone
#    diagram = opts.delete(:diagram)
#    if type.nil?
#      type = ""
#    else
#      type = ".#{type}" if type[0].chr != "."
#    end
#    "http://yuml.me/diagram/#{self.options_string(opts)}#{diagram}/#{data}#{type}"
#  end

  private

  def output(file, type="", diagram_options="")
    # http://yuml.me/diagram/nofunky;dir:TB;scale:120;/class/
    # http://yuml.me/diagram/nofunky;dir:TB;scale:180;/class/

    data = self.to_yumlme_dsl
    uri = "/diagram/#{@style}#{diagram_options}/class/#{data}#{type}"
    puts "*** #{uri}" if @options.debugging

    writer = STDOUT
    writer = open(file, "wb") unless file.nil?
    res = Net::HTTP.start("yuml.me", 80) {|http|
      http.get(URI.escape(uri))
    }
    writer.write(res.body)
    writer.close
  end

end