# frozen_string_literal: true

# RailsAdmin configuration

# RailsAdmin route is added in config/routes/ugent.rb under prefix "/admin"

# More configuration info can be found at https://github.com/sferik/rails_admin/wiki

RailsAdmin.config do |config|
  # because roadmap uses sprockets too
  config.asset_source = :sprockets

  # use ApplicationController as its parent class
  config.parent_controller = "::ApplicationController"

  config.current_user_method { current_user }

  config.authorize_with do |controller|

    if current_user.nil? || !(current_user.can_super_admin?)

      flash[:alert] = "not authorized"
      redirect_to main_app.root_path

    end

  end

  # only QuestionOption can be edited, and that in a very limited way
  # other stuff should be done in roadmap (some logic is contained not in their models but in their controllers)
  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new do
      only %w(Ugent::OrgDomain Ugent::RestUser Identifier)
    end
    export
    bulk_delete do
      only %w(Ugent::OrgDomain)
    end
    show
    edit do
      only %w(Question QuestionOption Ugent::OrgDomain Ugent::RestUser Identifier)
    end
    delete do
      only %w(Ugent::OrgDomain Ugent::RestUser Identifier)
    end
    show_in_app
  end

  # only allow these model in RailsAdmin
  config.included_models = [
    :Org,
    :'Ugent::OrgDomain',
    :'Ugent::RestUser',
    :Template,
    :Phase,
    :Section,
    :Question,
    :Theme,
    :QuestionOption,
    :Guidance,
    :Identifier,
    :User,
    :Plan
  ]

  config.model "Plan" do

    navigation_label "Plan management"
    label "Plan"
    label_plural "Plans"

  end

  config.model "User" do

    navigation_label "Organisation management"
    label "User"
    label_plural "Users"

  end

  config.model "Identifier" do

    navigation_label "Organisation management"
    label "Identifier"
    label_plural "Identifiers"

    weight 0
    object_label_method :value

    list do
      field :id
      field :identifier_scheme
      field :identifiable
      field :identifiable_type do
        filterable true
      end
      field :label
      field :value
      field :created_at
      field :updated_at
    end

    show do
      field :id
      field :identifier_scheme
      field :label
      field :value
      field :created_at
      field :updated_at
    end

    edit do
      field :identifier_scheme
      field :label
      field :value
      field :identifiable
      field :attrs
    end

  end

  config.model "Org" do

    navigation_label "Organisation management"
    label "Organisation"
    label_plural "Organisations"

    weight 0
    object_label_method :name

    list do
      field :id
      field :name
      field :abbreviation
      field :managed
      field :created_at
      field :updated_at
    end

  end

  config.model "Ugent::OrgDomain" do

    navigation_label "Organisation management"
    label "Organisation domain"
    label_plural "Organisation domains"

    weight 1
    object_label_method :name

  end

  config.model "Ugent::RestUser" do

    navigation_label "Organisation management"
    label "Org REST user"
    label_plural "Org REST users"

    weight 2
    object_label_method :code

  end

  config.model "Template" do

    # navigation labels are sorted!
    navigation_label "Template management"

    # "weight" is used to sort the models under its navigation_label
    weight 1
    object_label_method :title

    list do
      field :id
      field :title
      field :published
      field :org
      field :is_default
      field :family_id do
        read_only true
      end
      field :version do
        read_only true
      end
      field :customization_of do
        read_only true
      end
      field :archived do
        read_only true
      end
      field :created_at
      field :updated_at
    end

    show do
      field :id
      field :title
      field :description
      field :published
      field :org
      field :links
      field :is_default
      field :family_id
      field :version
      field :customization_of
      field :archived
      field :phases
      field :created_at
      field :updated_at
    end

  end

  config.model "Phase" do

    navigation_label "Template management"

    weight 2
    object_label_method :title

    list do
      field :id
      field :title
      field :number
      field :template
      field :created_at
      field :updated_at
    end

    show do
      field :id
      field :title
      field :description
      field :number
      field :template
      field :modifiable
      field :sections
    end

  end

  config.model "Section" do

    navigation_label "Template management"

    weight 3
    object_label_method :title

    list do
      field :id
      field :title
      field :number
      field :phase
      field :modifiable
      field :created_at
      field :updated_at
    end

    show do
      field :id
      field :title
      field :description
      field :number
      field :phase
      field :questions
      field :versionable_id
      field :modifiable
      field :created_at
      field :updated_at
    end

  end

  config.model "Question" do

    navigation_label "Template management"

    weight 4
    object_label_method :text

    list do
      field :id
      field :text
      field :question_format
      field :section
      field :created_at
      field :updated_at
    end

    show do
      field :id
      field :text
      field :question_format
      field :question_options
      field :themes
      field :number
      field :section
      field :created_at
      field :updated_at
    end

    edit do
      field :template do
        read_only true
        help ""
      end
      field :phase do
        read_only true
        help ""
      end
      field :section do
        read_only true
        help ""
      end
      field :number do
        read_only true
        help ""
      end
      field :text do
        read_only true
        help ""
      end
      field :themes do
        associated_collection_scope do
          Proc.new { |scope|
            scope.limit(100)
          }
        end
      end
    end

  end

  config.model "QuestionOption" do

    navigation_label "Template management"

    weight 5
    object_label_method :text

    list do
      field :id
      field :question
      field :text
      field :number
      field :is_default
      field :created_at
      field :updated_at
    end

    # only themes can be added
    # other fields added as readonly for context
    edit do
      field :template do
        read_only true
        help ""
      end
      field :phase do
        read_only true
        help ""
      end
      field :section do
        read_only true
        help ""
      end
      field :question do
        read_only true
        help ""
      end
      field :text do
        read_only true
        help ""
      end
      field :number do
        read_only true
        help ""
      end
      field :themes do
        associated_collection_scope do
          Proc.new { |scope|
            scope.limit(100)
          }
        end
      end
    end

  end

  config.model "Theme" do

    navigation_label "Template management"

    weight 6
    object_label_method :title

    list do
      sort_by :title
      field :id
      field :title
      field :description
      field :created_at
      field :updated_at
    end

    show do
      field :title
      field :description
      field :questions
      field :guidances
      field :created_at
      field :updated_at
    end

  end

  config.model "Guidance" do

    navigation_label "Template management"

    weight 7

  end

end
