# frozen_string_literal: true

# apparently these modules are not loaded yet, so there functionality does not work yet
require "user"
require "identifier"
require "org"
require "users/omniauth_callbacks_controller"
require "question_option"
require "plan"
require "theme"
require "phase"
require "template"
require "contributor"

# give contributor access to a plan
# TODO: what when contributor is removed? Remove also rights from plan.roles?
# TODO: make field "email" readonly in the form?
# TODO: make field "email" unique within plan?
Contributor.after_save do |contributor|

  role = plan.roles
             .select { |role| role.user.email == contributor.email }
             .first

  if role.nil?

    user = User.where(email: contributor.email).first

    if user.nil?

      user = User.new(email: contributor.email)
      user.save!

    end

    role = plan.roles.build(user: user)

  end

  if contributor.project_administration
    role.administrator = true
  end

  if contributor.data_curation
    role.editor = true
  end

  if contributor.investigation
    role.administrator = true
    role.editor = true
  end

  role.save!

end

class Template

  # Does a template contain personal data?
  # One question must include theme with title "UGENT:DATA"
  def gdpr?

    gdpr_theme = Theme.where(title: "UGENT:DATA").first
    return false if gdpr_theme.nil?

    questions.each do |q|
      return true if q.themes.include?(gdpr_theme)
    end

    false

  end

end

# disable feature that makes it possible to change the visibility
# See also app/views/branded/plans/_share_form.html.erb
class Phase

  def visibility_allowed?(plan)
    false
  end

end

class Plan

  def visibility_allowed?
    false
  end

end

# reuse old table that linked question options to themes
# this is neither present in the original DMPonline_v4 nor in roadmap
# beware that there is no model for this table, and it previously was called "options_themes",
class QuestionOption

  # ugent: couple themes to question_options
  # relations like this are automatically destroyed
  has_and_belongs_to_many :themes, join_table: "question_options_themes"

  # ugent: copy themes also
  # see also: QuestionOption#deep_copy
  def deep_copy(**options)
    copy = dup
    copy.question_id = options.fetch(:question_id, nil)
    copy.theme_ids = theme_ids
    copy.save!(validate: false)  if options.fetch(:save, false)
    options[:question_option_id] = copy.id
    copy
  end

end

class Theme

  # relations like this are automatically destroyed
  has_and_belongs_to_many :question_options, join_table: "question_options_themes"

end

class Identifier

  def value_uniqueness_with_scheme
    # override - start
    # Org may have multiple login routes of the same type
    return true if identifier_scheme.name == "shibboleth" && identifiable_type == "Org"

    # same orcid may be attached to several users
    return true if identifier_scheme.name == "orcid" && identifiable_type == "User"

    # override - end
    # old code
    if Identifier.where(identifier_scheme: identifier_scheme,
                        identifiable: identifiable).any?
      errors.add(:identifier_scheme, _("already assigned a value"))
    end
  end

end

class User

  def ensure_password
    generate_password unless encrypted_password.present?
  end

  # rubocop: disable Lint/UselessAssignment
  def generate_password
    password = Devise.friendly_token[0, 20]
    password_confirmation = password
  end
  # rubocop: enable Lint/UselessAssignment

  def guest?
    org_id == Org.guest.id
  end

  def self.nemo
    "n.n."
  end

  def nemo?
    firstname.blank? || surname.blank? || firstname == User.nemo || surname == User.nemo
  end

  def alternative_accounts
    scheme = IdentifierScheme.find_by_name("orcid")
    orcid = identifiers.select { |id| id.identifier_scheme_id == scheme.id }.first

    return [] if orcid.nil?

    Identifier.where(
      "identifier_scheme_id = ? AND identifiable_type = ? AND value = ? AND identifiable_id <> ?",
      scheme.id,
      "User",
      orcid.value,
      id
    )
              .map(&:identifiable)
  end

end

User.before_validation do |user|
  # downcase email of new user
  if user.new_record?

    user.email.downcase! if user.email.present?

  # do not allow email changes
  # TODO: keep?
  elsif user.email_changed?

    user.email = user.email_was

  end

  # only (re)set organisation during creation
  if user.new_record? || user.org.nil?

    if user.email.present?

      parts_email = user.email.split("@")
      if parts_email.size == 2

        org_domain = Ugent::OrgDomain.where(name: parts_email[1]).first
        user.org = org_domain.present? ? org_domain.org : Org.guest

      end

    else

      user.org = Org.guest

    end

  end

  user.ensure_password
  user.firstname = User.nemo if user.firstname.blank?
  user.surname = User.nemo if user.surname.blank?

  true
end

class Org

  has_many :domains, class_name: "Ugent::OrgDomain"

  def self.guest
    where(abbreviation: "guests").first
  end

end

module Users

  class OmniauthCallbacksController

    # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
    def handle_shibboleth(scheme)
      auth = request.env["omniauth.auth"]

      # find user by existing identifier
      user = User.from_omniauth(auth)

      # If the user isn't logged in
      if current_user.nil?

        # no user found: two reasons:
        #   1) no user in table users
        #   2) no identifier of scheme shibboleth yet

        user = User.find_by_email(auth.uid) if user.nil?

        # still no user: create one
        if user.nil?

          email = auth["extra"].try("raw_info").try("mail")
          user = User.new(email: email.downcase)
          user.surname = auth["extra"].try("raw_info").try("sn")
          user.firstname = auth["extra"].try("raw_info").try("givenname")

          unless user.save

            flash[:alert] = user.errors.full_messages
            redirect_to root_path
            return

          end

        end

        # attach shibboleth identifiers for future use
        if user.identifiers
               .select { |id| id.identifier_scheme_id == scheme.id }
               .empty?

          if Identifier.create(identifier_scheme: scheme,
                               value: auth.uid,
                               attrs: auth,
                               identifiable: user)

            flash[:notice] = _("Your account has been successfully linked to %{scheme}.") % {
              scheme: scheme.description
            }

          else

            flash[:alert] = _("Unable to link your account to %{scheme}.") % {
              scheme: scheme.description
            }

          end

        end

        sign_in(user)

      # The user is already logged in and just registering the uid with us
      # If the user could not be found by that uid then attach it to their record
      elsif user.nil?

        if Identifier.create(identifier_scheme: scheme,
                             value: auth.uid,
                             attrs: auth,
                             identifiable: current_user)
          flash[:notice] = _("Your account has been successfully linked to %{scheme}.") % {
            scheme: scheme.description
          }

        else

          flash[:alert] = _("Unable to link your account to %{scheme}.") % {
            scheme: scheme.description
          }

        end

      # If a user was found but does NOT match the current user then the identifier has
      # already been attached to another account (likely the user has 2 accounts)
      elsif user.id != current_user.id

        flash[:alert] = _("The current #{scheme.description} iD has been already linked to a user with email #{identifier.user.email}")

      end

      # Redirect to the User Profile page
      redirect_to edit_user_registration_path
    end
    # rubocop: enable Metrics/MethodLength, Metrics/AbcSize

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def handle_orcid(scheme)
      auth = request.env["omniauth.auth"]

      Rails.logger.info("auth: #{auth}")

      # when saved, identifier of scheme "orcid" is prefixed with the identifier_prefix of the corresponding scheme
      full_uid = scheme.identifier_prefix + auth.uid

      # The user is already logged in and just registering the uid with us
      # Action: attach id and redirect to profile page
      if current_user.present?

        Rails.logger.info("found current_user")

        existing_id = current_user.identifiers
                                  .select { |id| id.value == full_uid && id.identifier_scheme_id == scheme.id }
                                  .first

        if existing_id.nil?

          if Identifier.create(identifier_scheme: scheme,
                               value: auth.uid,
                               attrs: auth,
                               identifiable: current_user)
            flash[:notice] = _("Your account has been successfully linked to %{scheme}.") % {
              scheme: scheme.description
            }

          else

            flash[:alert] = _("Unable to link your account to %{scheme}.") % {
              scheme: scheme.description
            }

          end

        else

          flash[:alert] = _("Your account has already been linked to %{scheme}") % {
            scheme: scheme.description
          }

        end

        redirect_to edit_user_registration_path
        return

      end

      # User is not logged in

      # Match orcid with one of more users
      selectable_users = Identifier.where(identifiable_type: "User", identifier_scheme_id: scheme.id, value: full_uid)
                                   .map(&:identifiable)

      # TODO: create controller
      if selectable_users.size > 1

        session[:selectable_user_ids] = selectable_users.map(&:id)
        redirect_to edit_selectable_user_path
        return

      end

      Rails.logger.info("selectable_users: #{selectable_users.map(&:attributes)}")

      email = auth["info"]["email"]

      user = selectable_users.first

      # Match on ORCID: OK
      if user

        # set firstname and surname when not present yet
        user.firstname = auth["info"]["first_name"] if user.firstname.blank? || user.firstname == User.nemo
        user.surname = auth["info"]["last_name"] if user.surname.blank? || user.surname == User.nemo

      # Match on primary email: OK
      # this user's orcid must be empty or different
      # attribute 'email' is unique (enforced by devise?)
      elsif email.present? && (user = User.where(email: email).first)

        existing_id = user.identifiers
                          .select { |id| id.value == full_uid && id.identifier_scheme_id == scheme.id }
                          .first

        if existing_id.nil?

          if Identifier.create(identifier_scheme: scheme,
                               value: auth.uid,
                               attrs: auth,
                               identifiable: user)

            flash[:notice] = _("Your account has been successfully linked to %{scheme}.") % {
              scheme: scheme.description
            }

          else

            flash[:alert] = _("Unable to link your account to %{scheme}.") % {
              scheme: scheme.description
            }

          end

        end

      # Match on primary email: false
      # NEW USER. We trust "email" because ORCID marks it as confirmed
      elsif email.present?

        user = User.new(
          email: email,
          firstname: auth["info"]["first_name"],
          surname: auth["info"]["last_name"]
        )

        unless user.save

          flash[:alert] = user.errors.full_messages
          redirect_to root_url

        end

        if Identifier.create(identifier_scheme: scheme,
                             value: auth.uid,
                             attrs: auth,
                             identifiable: user)

          flash[:notice] = _("Your account has been successfully linked to %{scheme}.") % {
            scheme: scheme.description
          }

        else

          flash[:alert] = _("Unable to link your account to %{scheme}.") % {
            scheme: scheme.description
          }

        end

      # No orcid, no email: warn user
      else

        flash[:alert] = "Unable to login with orcid: try setting the visibility of your email address to \"everyone\" or \"trusted parties\" (<a href=\"https://orcid.org/account\">orcid profile</a>)"
        redirect_to root_url
        return

      end

      set_flash_message(:notice, :success, kind: scheme.description) if is_navigational_format?
      sign_in_and_redirect user, event: :authentication
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def handle_omniauth(scheme)
      if scheme.name == "shibboleth"
        handle_shibboleth(scheme)
      elsif scheme.name == "orcid"
        handle_orcid(scheme)
      end
    end

  end

end

# not used at the moment. Remove?
DMPRoadmap::Application.class_eval do
  config.custom = config_for(:custom) if File.exist?(Rails.root.join("config", "custom.yml"))
end
