# frozen_string_literal: true

# apparently these modules are not loaded yet, so their functionality does not work yet
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
require "role"
require "plan_policy"

class PlanPolicy

  # guest user should not be able to access the plan creation wizard
  # action new? determined by create? (see app/models/application_policy.rb)
  def create?
    @user.present? && !@user.guest?
  end

end

# To remove when Ugent::Internal::ExportsController is removed
class Role

  # Purpose: access level to be shown in internal_exports_controller per Role
  #   taken from old ProjectGroup
  def code_access_level
    if creator
      return :owner
    elsif administrator
      return :co_owner
    elsif editor
      return :editor
    elsif commenter
      return :commenter
    elsif reviewer
      return :reviewer
    end
    :read_only
  end

end

class Contributor

  # update contributor based on user data
  # note: only do this for contributors with the same email!
  def update_from_user(user)

    # update user data
    self.name    = user.nemo? ? User.nemo : "#{user.firstname} #{user.surname}"
    self.org_id  = user.org_id

    # update contributor identifier
    scheme_orcid = User.identifier_scheme_orcid
    user_orcid   = user.identifiers
                       .select { |id| id.identifier_scheme_id == scheme_orcid.id }
                       .first

    contr_orcid = nil

    if user_orcid.present?

      contr_orcid = self.identifiers
                        .select { |id| id.identifier_scheme_id == scheme_orcid.id }
                        .first

      if contr_orcid.nil?

        contr_orcid = self.identifiers
                          .build(identifier_scheme_id: scheme_orcid.id, value: user_orcid.value)

      else

        contr_orcid.value = user_orcid.value

      end

    end

    if contr_orcid.nil?

      identifiers = []

    else

      identifiers = [contr_orcid]

    end

  end

end

# Automatically synchronise user data to contributors
User.after_save do |user|

  next if user.previous_changes.empty?

  Contributor.where(email: user.email)
             .update_all(
                name: user.nemo? ? User.nemo : "#{user.firstname} #{user.surname}",
                org_id: user.org_id)

end

# Automatically update/create identifier orcid in Contributor when User orcid is created/updated
Identifier.after_save do |id|

  next if id.previous_changes.empty?

  next unless id.identifiable_type == "User"

  next unless id.identifier_scheme_id == User.identifier_scheme_orcid.id

  user = id.identifiable

  Contributor.includes(:identifiers)
             .where(email: user.email)
             .each do |contributor|

    orcids = contributor.identifiers.select { |i| i.identifier_scheme_id == User.identifier_scheme_orcid.id }
    next if orcids.size > 0
    contributor.identifiers
               .build(identifier_scheme: User.identifier_scheme_orcid, value: id.value)
               .save

  end

end

# Automatically (co)owners and editors as contributors
Role.after_save do |role|

  plan = role.plan
  user = role.user
  contributor = plan.contributors
                    .select { |contributor| contributor.email == user.email }
                    .first

  if contributor.nil?
    contributor = plan.contributors.build(email: user.email)
  end

  # update permissions (set all to prevent incremental updates)
  contributor.roles = 0
  if role.creator || role.administrator

    contributor.investigation = true

  elsif role.editor

    contributor.project_administration = true

  end

  # remove if no roles
  if contributor.roles == 0

    contributor.destroy

  else

    # update user data
    contributor.update_from_user(user)

    contributor.save!

  end

end

Role.after_destroy do |role|

  plan = role.plan
  user = role.user
  contributor = plan.contributors
                    .select { |contributor| contributor.email == user.email }
                    .first

  # update permissions
  if role.creator || role.administrator

    contributor.investigation = false

  elsif role.editor

    contributor.project_administration = false

  end

  # destroy contributor when no permissions are left (roles == 0 is not allowed)
  if contributor.roles == 0
    contributor.destroy
  end

end

class Template

  # Does a template contain personal data?
  # One question must include theme with title "UGENT:DATA"
  def gdpr?

    gdpr_theme = Theme.where(title: "UGENT:DATA").first
    return false if gdpr_theme.nil?

    phases.each do |phase|
      phase.sections.each do |section|
        section.questions.each do |q|
          return true if q.themes.include?(gdpr_theme)
        end
      end
    end

    false

  end

end

class Plan

  # To remove when Ugent::Internal::ExportsController is removed
  # Purpose: deprecated json api ugent/internal_exports_controller.rb
  def ld_uri

    Rails.application.routes.url_helpers.plan_url(self, host: ENV["DMP_HOST"], protocol: ENV["DMP_PROTOCOL"])

  end

  # To remove when Ugent::Internal::ExportsController is removed
  def ld

    # old Project == new Plan
    # TODO: data contact and principal investigator not recognisable..
    pr = {
      id: id,
      type: "Project",
      url: ld_uri,
      created_at: created_at.utc.strftime("%FT%TZ"),
      updated_at: updated_at.utc.strftime("%FT%TZ"),
      title: title,
      description: description,
      identifier: identifier,
      grant_number: grant_number,
      collaborators: roles.map { |role|
        # collaborators -> plan.roles -> old project groups
        u = role.user
        pg_r = {
          type: "ProjectGroup",
          user: nil,
          access_level: role.code_access_level,
          created_at: role.created_at.utc.strftime("%FT%TZ"),
          updated_at: role.updated_at.utc.strftime("%FT%TZ")
        }
        unless u.nil?

          orcid = u.identifier_orcid

          pg_r[:user] = {
            id: u.id,
            type: "User",
            created_at: u.created_at.utc.strftime("%FT%TZ"),
            updated_at: u.updated_at.utc.strftime("%FT%TZ"),
            email: u.email,
            orcid: orcid.present? ? orcid.value : nil
          }

        end
        pg_r
      },
      organisation: nil,
      plans: []
    }

    # presence of "org" only proves that this plan
    #   was created with this organisation selected for extra guidance
    # See https://github.com/DMPRoadmap/roadmap/issues/2801
    owning_org = owner.present? && owner.org.present? ? owner.org : nil
    if owning_org.present?

      pr[:organisation] = {
        type: "Organisation",
        id: owning_org.id,
        name: owning_org.name
      }

    end

    pr[:template] = {
      id: template.id,
      created_at: template.created_at.utc.strftime("%FT%TZ"),
      updated_at: template.updated_at.utc.strftime("%FT%TZ"),
      title: template.title,
      description: template.description,
      published: template.published,
      is_default: template.is_default,
      gdpr: template.gdpr?,
      type: "Template"
    }
    pr[:template][:type] = "Template"

    if funder.present?

      pr[:funder] = {
        type: "Organisation",
        id: funder.id,
        name: funder.name
      }

    elsif funder_name.present?

      pr[:funder] = {
        type: nil,
        id: nil,
        name: funder_name
      }

    else

      pr[:funder] = nil

    end

    pr[:plans] = []

    plan_answers = answers.all

    question_formats = QuestionFormat.all

    template.phases.each do |phase|

      pl = {
        version: {
          type: "Version",
          id: phase.versionable_id,
          title: phase.title
        },
        id: phase.id,
        type: "Plan",
        url: ld_uri + "/edit?phase_id=" + phase.id.to_s,
        sections: []
      }

      phase.sections.each do |section|

        sc = {
          id: section.id,
          type: "Section",
          number: section.number,
          title: section.title,
          questions: []
        }

        section.questions
               .sort { |a,b| a.number <=> b.number }
               .each do |question|

          question_format = question_formats.select { |qf| qf.id == question.question_format_id }.first

          q = {
            id: question.id,
            type: "Question",
            text: question.text,
            default_value: question.default_value,
            number: question.number,
            question_format: {
              id: question_format.id,
              type: "QuestionFormat",
              title: question_format.title,
              description: question_format.description,
              created_at: question_format.created_at.utc.strftime("%FT%TZ"),
              updated_at: question_format.updated_at.utc.strftime("%FT%TZ")
            },
            # should only be of one org
            suggested_answers: question.annotations
                                       .select { |annotation| annotation.type == Annotation.types[:example_answer] }
                                       .select { |annotation| annotation.text.present? }
                                       .map { |annotation|

              {
                id: annotation.id,
                type: "SuggestedAnswer",
                text: annnotation.text,
                is_example: true,
                created_at: annotation.created_at.utc.strftime("%FT%TZ"),
                updated_at: annotation.created_at.utc.strftime("%FT%TZ")
              }

            },
            answer: nil,
            themes: question.themes.map { |theme|
              {
                id: theme.id,
                type: "Theme",
                title: theme.title,
                created_at: theme.created_at.utc.strftime("%FT%TZ"),
                updated_at: theme.updated_at.utc.strftime("%FT%TZ")
              }
            }
          }

          # select answer from plan related answers we have precollected
          answer = plan_answers.select { |a| a.question_id == question.id }.first

          if question_format.option_based?

            q[:options] = question.question_options.sort_by(&:number).map do |op|
              {
                id: op.id,
                type: "Option",
                text: op.text,
                number: op.number,
                is_default: op.is_default,
                created_at: op.created_at.utc.strftime("%FT%TZ"),
                updated_at: op.created_at.utc.strftime("%FT%TZ"),
                themes: op.themes.map { |theme|
                  {
                    id: theme.id,
                    type: "Theme",
                    title: theme.title,
                    created_at: theme.created_at.utc.strftime("%FT%TZ"),
                    updated_at: theme.updated_at.utc.strftime("%FT%TZ")
                  }
                }
              }
            end

          end

          if answer.present? && question_format.option_based?

            q[:selected] = {}

            answer.question_options.each do |o|

              q[:selected][o.number] = o.text

            end

          end

          if answer.present?

            au = answer.user
            identifier_orcid = au.identifier_orcid
            q[:answer] = {
              id: answer.id,
              type: "Answer",
              text: answer.text,
              user: nil,
              created_at: answer.created_at.utc.strftime("%FT%TZ"),
              updated_at: answer.updated_at.utc.strftime("%FT%TZ")
            }
            unless au.nil?

              q[:answer][:user] = {
                id: au.id,
                type: "User",
                email: au.email,
                orcid: identifier_orcid.present? ? identifier_orcid.value : nil
              }

            end

          end

          q[:comments] = []

          # old question.comments is now answer.notes
          # so not only change of name, but also tied now to an answer instead of a question
          if answer.present?

            answer.notes.each do |note|

              c = {
                id: note.id,
                type: "Comment",
                created_at: note.created_at.utc.strftime("%FT%TZ"),
                updated_at: note.updated_at.utc.strftime("%FT%TZ"),
                text: note.text,
                created_by: nil,
                archived_by: nil,
                archived: note.archived ? true : false
              }

              created_by = note.user

              if created_by.present?

                identifier_orcid = created_by.identifier_orcid

                c[:created_by] = {
                  id: created_by.id,
                  type: "User",
                  email: created_by.email,
                  orcid: identifier_orcid.present? ? identifier_orcid.value : nil
                }

              end

              archived_by = note.archived_by.present? ? User.find(note.archived_by) : nil

              if archived_by.present?

                identifier_orcid = archived_by.identifier_orcid

                c[:archived_by] = {
                  id: archived_by.id,
                  type: "User",
                  email: archived_by.email,
                  orcid: identifier_orcid.present? ? identifier_orcid.value : nil
                }

              end

              q[:comments] << c

            end

          end

          sc[:questions] << q

        end

        pl[:sections] << sc

      end

      pr[:plans] << pl

    end

    pr

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
    if new_record? && Identifier.where(identifier_scheme: identifier_scheme,
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

  def self.identifier_scheme_orcid
    @identifier_scheme_orcid ||= IdentifierScheme.find_by_name("orcid")
  end

  def identifier_orcid
    scheme = User.identifier_scheme_orcid
    identifiers.select { |id| id.identifier_scheme_id == scheme.id }.first
  end

  def alternative_accounts
    orcid = identifier_orcid

    return [] if orcid.nil?

    Identifier.where(
      "identifier_scheme_id = ? AND identifiable_type = ? AND value = ? AND identifiable_id <> ?",
      orcid.identifier_scheme_id,
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

  # users whose email address does not belong to any organisation domains
  # become part of the guest org
  def self.guest
    where(abbreviation: "guests").first
  end

  # To remove when Ugent::Internal::ExportsController is removed
  # internal export per organisation
  def internal_export_dir

    File.join(
      (ENV["INTERNAL_EXPORTS"].present? ?
        ENV["INTERNAL_EXPORTS"] : "/opt/dmponline_internal"),
      abbreviation
    )

  end

  # To remove when Ugent::Internal::ExportsController is removed
  # <base_url>/internal/exports/v01/organisations/<org.abbreviation>
  def internal_export_url

    hst   = ENV["DMP_HOST"].present? ? ENV["DMP_HOST"] : "localhost:3000"
    prot  = ENV["DMP_PROTOCOL"].present? ? ENV["DMP_PROTOCOL"] : "http"

    u = Rails.application
      .routes
      .url_helpers
      .root_url(host: hst, protocol: prot)
    u.chomp!("/")
    u += "/internal/exports/v01/organisations/" + abbreviation
    u

  end

  # To remove when Ugent::Internal::ExportsController is removed
  def internal_export_files

    base_dir = internal_export_dir
    base_url = internal_export_url

    files = Dir
      .glob( File.join(base_dir, "*", "*", "*.json") )
      .map { |f|

        rel_name = f.gsub(base_dir + "/" , "" )
        full_url = base_url + "/" + rel_name
        self_url = base_url + "/" + rel_name

        {
          id => full_url,
          type: "file",
          links: { self: self_url },
          attributes => {
            updated_at: File.mtime(f).utc.strftime("%FT%TZ")
          }
        }

      }

    files += Dir
      .glob( File.join(base_dir,"*.json") )
      .select { |f| File.symlink?(f) }
      .map { |f|

        rel_name = f.gsub(base_dir + "/" , "")
        full_url = base_url + "/" + rel_name
        self_rel_name = File.readlink(f).gsub(base_dir + "/" , "")
        self_url = base_url + "/" + self_rel_name

        {
          id: full_url,
          type: "link",
          links: { self: self_url },
          attributes: {
            updated_at: File.mtime(f).utc.strftime("%FT%TZ")
          }
        }

      }

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

      # Redirect to root url
      redirect_to root_url
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
