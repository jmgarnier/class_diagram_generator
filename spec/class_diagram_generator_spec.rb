require File.dirname(__FILE__) + '/spec_helper'

describe "Class diagram generator" do

  def show_generated_png(diagram)
    png_file_path = "#{File.dirname(__FILE__)}/class-diagram.png"
    diagram.to_png(png_file_path, ";dir:TB;scale:180;")
    File.file?(png_file_path).should be_true
    `open #{png_file_path}`
  end

  describe "Outputting with yuml.me" do
    before(:each) do
      @diagram = ClassDiagramGenerator.new.with_classes(User)
    end

    it "should save to a png file" do
      # show_generated_png diagram
    end

    it "can add a note" do
      @diagram.with_note("Hello World").to_yumlme_dsl.should include("[note: Hello World]")
    end
  end

  describe "When making a diagram for a Model class" do

    it "should generate a class diagram for a given Model, without displaying attributs by default" do
      diagram = ClassDiagramGenerator.new.with_classes(User)
      diagram.to_yumlme_dsl.should == "[User]"
      # show_generated_png diagram
    end

    it "should generate a class diagram for a given Model, with attributes " do
      diagram = ClassDiagramGenerator.new.with_classes(User)

      diagram.show_attributes.to_yumlme_dsl.
              should == "[User|first_name;last_name]"
      # show_generated_png diagram
    end

    it "should generate a diagram for a list of Models" do
      diagram = ClassDiagramGenerator.new.with_classes(User, Project)
      diagram.to_yumlme_dsl.should == "[User],[Project]"
      # show_generated_png diagram
    end

    it "should generate a diagram for an array of Models" do
      diagram = ClassDiagramGenerator.new.with_classes([User, Project])
      diagram.to_yumlme_dsl.should == "[User],[Project]"
      # show_generated_png diagram
    end

    it "should find all Models using introspection" do
      diagram = ClassDiagramGenerator.new.show_debugging.with_all_model_classes("spec/app/models/*.rb")
      # show_generated_png diagram
      diagram.to_yumlme_dsl.
              should == "[Base],[Category],[Element],[Friendship],[Organisation],[Project],[ProjectMailer],[User],[UserMailer]"
    end

    it "should generate a diagram for Models whose filename follows a pattern" do
      diagram = ClassDiagramGenerator.new.with_all_model_classes("spec/app/models/*_mailer.rb")
      diagram.to_yumlme_dsl.should == "[ProjectMailer],[UserMailer]"
      # show_generated_png diagram
    end

    it "should generate a diagram for Models whose filename follows a pattern and excluding some file(s)" do
      diagram = ClassDiagramGenerator.new.with_all_model_classes("spec/app/models/*_mailer.rb", ["spec/app/models/user_mailer.rb"])
      diagram.to_yumlme_dsl.should == "[ProjectMailer]"
      # show_generated_png diagram
    end

    it "should exclude ActiveRecord methods from public business logic methods list" do
      diagram = ClassDiagramGenerator.new.with_classes(User).show_public_methods
      # show_generated_png diagram
      diagram.to_yumlme_dsl.
              should == "[User|+business_method]"
    end

    it "should generate a diagram showing all the ancestors exluding ActiveRecord::Base" do
      diagram = ClassDiagramGenerator.new.with_classes(Project)
      diagram.show_inheritance.to_yumlme_dsl.
              should == "[Base]^-[Project]"
    end

    describe "Introspecting associations" do

      before :each do
        managed_projects_association = User.reflect_on_association(:managed_projects)
        @association = ActiveRecord::Metadata::Association.new(User, managed_projects_association)
      end

      describe ActiveRecord::Metadata::Association do
        it "should get informations about association using reflection" do
          @association.from_class_name.should == "User"
          @association.type.should == "has_many"
          @association.name.should == "managed_projects"
          @association.cardinality.should == "*"
          @association.to_class_name.should == "Project"
        end
      end

      describe ActiveRecord::Metadata do
        before :each do
          @associations_metadata = ActiveRecord::Metadata.new
          @associations_metadata.add_association @association
        end

        it "should add association to the corresponding graph" do
          @associations_metadata.include_link_for_association?(@association).should be_true
        end

        it "should compile a agregated_label_for_association" do
          @associations_metadata.agregated_label_for_association(@association).should == " managed"
        end
      end

      describe ActiveRecord::Metadata::Graph do
        before :each do
          @associations_graph = ActiveRecord::Metadata::Graph.new
        end

        it "should return true if there is link btw 2 nodes" do
          @associations_graph.add_edge "User", "Project"
          @associations_graph.should have_edge_between("User", "Project")
          @associations_graph.should_not have_edge_between("Project", "User")
        end

        it "should return false if one of the node does not exist" do
          @associations_graph.should_not have_edge_between("User", "Project")
          @associations_graph.should_not have_edge_between("Project", "User")
        end

        it "should collect association names and append them to a pretty & readable label sorted alphabetically" do
          @associations_graph.add_edge "User", "Project"
          @associations_graph.add_edge "User", "Project", "published_projects"
          @associations_graph.add_edge "User", "Project", "managed_projects"
          @associations_graph.add_edge "User", "Project", "non_charity_projects"
          @associations_graph.add_edge "User", "Project", "unpublished_projects"
          @associations_graph.add_edge "User", "Project", "some_other_stuffs"

          @associations_graph.label_for_edge("User", "Project").
                  should == " managed / non charity / published / some other stuffs / unpublished"
        end

      end

      it "should generate a class diagram for a given Model, with associations belong_to " do
        diagram = ClassDiagramGenerator.new.with_classes(Project, Category).show_associations
        diagram.to_yumlme_dsl.
                should == "[Project],[Project]-belongs_to >[Category],[Category],[Category]-has_many >*[Project]"

        # show_generated_png diagram
      end

      it "should generate a class diagram for a given Model, with associations has_many" do
        diagram = ClassDiagramGenerator.new.with_classes(Project, Element).show_associations # .show_debugging
        diagram.to_yumlme_dsl.
                should == "[Project],[Project]-has_many completed / expired / incomplete / money / unexpired >*[Element],[Element],[Element]-belongs_to >[Project]"

        # show_generated_png diagram
      end

      # has_one :child, :class_name => 'Friendship', :foreign_key => 'parent_id', :dependent => :delete
      # belongs_to :parent, :class_name => 'Friendship'

      it "should handle has_one association" do
        diagram = ClassDiagramGenerator.new.with_classes(Friendship).show_associations #.show_debugging
        diagram.to_yumlme_dsl.should == "[Friendship],[Friendship]-has_one child >1[Friendship],[Friendship]-belongs_to parent >[Friendship]"
      end

      it "should handle association has_many :through" do
        diagram = ClassDiagramGenerator.new.with_classes(User, Friendship).show_associations #.show_debugging
        diagram.to_yumlme_dsl.should include("[User]-has_through friends >*[User]")
      end

      it "should have maxium one association btw 2 models in order to not to make the diagram unreadable with arrows everywhere" do
        diagram = ClassDiagramGenerator.new.with_classes(User, Organisation, Project, Element).show_associations #.show_debugging
        diagram.to_yumlme_dsl.should ==
                "[User],[User]-has_many managed >*[Project],[Organisation],[Project],[Project]-has_many completed / expired / incomplete / money / unexpired >*[Element],[Element],[Element]-belongs_to >[Project]"
      end

    end

  end

  describe "Class with public methods" do

    it "should generate a diagram for a Model with public methods, sorted alphabetically" do
      diagram = ClassDiagramGenerator.new.with_classes(ProjectsController)
      diagram.show_public_methods.to_yumlme_dsl.
              should == "[ProjectsController|+custom_action]"
      # show_generated_png diagram
    end

    it "should not show public methods of Rails base class" do
      diagram = ClassDiagramGenerator.new.with_classes(ActionController::Base)
      diagram.show_public_methods.to_yumlme_dsl.
              should == "[ActionController::Base]"
    end

  end

  describe "Making a diagram for Controller classes" do

    it "should get the hierarchy of a Controller without Object" do
      ProjectsController.hierarchy.should == [ActionController::Base, ApplicationController, ProjectsController]
    end

    it "should generate a diagram showing all the ancestors up to ActionController::Base" do
      diagram = ClassDiagramGenerator.new.with_classes(ProjectsController)
      diagram.show_inheritance.to_yumlme_dsl.
              should == "[ActionController::Base]^-[ApplicationController],[ApplicationController]^-[ProjectsController]"
    end

    it "should generate a diagram showing all the ancestors up to ActionController::Base and do not dupplicate super classes hierarchy" do
      diagram = ClassDiagramGenerator.new.with_classes(ProjectsController, UsersController)
      diagram.show_inheritance.to_yumlme_dsl.
              should == "[ActionController::Base]^-[ApplicationController],[ApplicationController]^-[ProjectsController],[ApplicationController]^-[UsersController]"
    end

    it "should find all controllers using introspection" do
      diagram = ClassDiagramGenerator.new.with_all_controller_classes("spec/app/controllers/**/*_controller.rb")
      # show_generated_png diagram
      diagram.to_yumlme_dsl.
              should == "[ProjectsController],[UsersController]"
    end

    # Process exception 
    # undefined method `hierarchy' for Admin2::AccountingController:Module

  end

end