namespace :class_diagram do

  def doc_diagrams_folder
    folder = File.join(Dir.pwd, "doc/diagrams/")
    FileUtils.mkdir(folder) unless File.directory?(folder)
    folder
  end

  def load_controller_classes(except)
    # before Rails 2.3
    require "app/controllers/application.rb" if File.exists?("app/controllers/application.rb")

    # from Rails >= 2.3.x
    require "app/controllers/application_controller.rb" if File.exists?("app/controllers/application_controller.rb")

    files = Dir.glob("app/controllers/**/*_controller.rb") - except
    files.each {|c| require c }
  end

  def except_files
    # FIXME convert a comma separated list to an array, there must be some examples around
    [ ENV['EXCEPT'] ] || []
  end

  desc "generate controllers class diagram"
  task :controllers => :environment do
    load_controller_classes(except_files)

    png_file_path = doc_diagrams_folder + "controllers_class_diagram.png"
    ClassDiagramGenerator.new.
            with_all_controller_classes("app/controllers/**/*_controller.rb", except_files).
            show_inheritance.
            show_public_methods.
              to_png(png_file_path, ";dir:TB;")

    puts "generating diagram for controllers"

    `open #{png_file_path}`
  end

  desc "generate models class diagram"
  task :models => :environment do
    png_file_path = doc_diagrams_folder + "models_class_diagram.png"

    ClassDiagramGenerator.new.
            with_all_model_classes("app/models/**/*.rb", except_files).
            show_inheritance.
            show_associations.
            show_public_methods.show_debugging.
            with_note("Class diagram for all models").
              to_png(png_file_path, ";dir:TB;scale:180;")

    puts "generating diagram for models"

    `open #{png_file_path}`
  end

end
