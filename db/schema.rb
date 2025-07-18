# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_08_12_124800) do

  create_table "annotations", id: :integer, force: :cascade do |t|
    t.integer "question_id"
    t.integer "org_id"
    t.text "text"
    t.integer "type", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "versionable_id", limit: 36
    t.index ["org_id"], name: "fk_rails_aca7521f72"
    t.index ["question_id"], name: "index_annotations_on_question_id"
    t.index ["versionable_id"], name: "index_annotations_on_versionable_id"
  end

  create_table "answers", id: :integer, force: :cascade do |t|
    t.text "text", limit: 16777215
    t.integer "plan_id"
    t.integer "user_id"
    t.integer "question_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lock_version", default: 0
    t.index ["plan_id"], name: "index_answers_on_plan_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["user_id"], name: "fk_rails_584be190c2"
  end

  create_table "answers_question_options", id: false, force: :cascade do |t|
    t.integer "answer_id", null: false
    t.integer "question_option_id", null: false
    t.index ["answer_id"], name: "index_answers_question_options_on_answer_id"
    t.index ["question_option_id"], name: "fk_rails_01ba00b569"
  end

  create_table "api_clients", id: :integer, force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "homepage"
    t.string "contact_name"
    t.string "contact_email", null: false
    t.string "client_id", null: false
    t.string "client_secret", null: false
    t.datetime "last_access"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "org_id"
    t.index ["name"], name: "index_api_clients_on_name"
  end

  create_table "conditions", id: :integer, force: :cascade do |t|
    t.integer "question_id"
    t.text "option_list"
    t.integer "action_type"
    t.integer "number"
    t.text "remove_data"
    t.text "webhook_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_conditions_on_question_id"
  end

  create_table "contributors", id: :integer, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.integer "roles", null: false
    t.integer "org_id"
    t.integer "plan_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["email"], name: "index_contributors_on_email"
    t.index ["org_id"], name: "index_contributors_on_org_id"
    t.index ["plan_id"], name: "index_contributors_on_plan_id"
    t.index ["roles"], name: "index_contributors_on_roles"
  end

  create_table "departments", id: :integer, force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.integer "org_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["org_id"], name: "index_departments_on_org_id"
  end

  create_table "exported_plans", id: :integer, force: :cascade do |t|
    t.integer "plan_id"
    t.integer "user_id"
    t.string "format"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "phase_id"
  end

  create_table "guidance_groups", id: :integer, force: :cascade do |t|
    t.string "name"
    t.integer "org_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "optional_subset", default: false, null: false
    t.boolean "published", default: false, null: false
    t.index ["org_id"], name: "index_guidance_groups_on_org_id"
  end

  create_table "guidances", id: :integer, force: :cascade do |t|
    t.text "text", limit: 16777215
    t.integer "guidance_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published"
    t.index ["guidance_group_id"], name: "index_guidances_on_guidance_group_id"
  end

  create_table "identifier_schemes", id: :integer, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.boolean "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "logo_url"
    t.text "identifier_prefix"
    t.integer "context"
  end

  create_table "identifiers", id: :integer, force: :cascade do |t|
    t.string "value", null: false
    t.text "attrs"
    t.integer "identifier_scheme_id"
    t.integer "identifiable_id"
    t.string "identifiable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "label"
    t.index ["identifiable_type", "identifiable_id"], name: "index_identifiers_on_identifiable_type_and_identifiable_id"
    t.index ["identifier_scheme_id", "identifiable_id", "identifiable_type"], name: "index_identifiers_on_scheme_and_type_and_id"
    t.index ["identifier_scheme_id", "value"], name: "index_identifiers_on_identifier_scheme_id_and_value"
  end

  create_table "languages", id: :integer, force: :cascade do |t|
    t.string "abbreviation"
    t.string "description"
    t.string "name"
    t.boolean "default_language"
  end

  create_table "licenses", force: :cascade do |t|
    t.string "name", null: false
    t.string "identifier", null: false
    t.string "uri", null: false
    t.boolean "osi_approved", default: false
    t.boolean "deprecated", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier", "osi_approved", "deprecated"], name: "index_license_on_identifier_and_criteria"
    t.index ["identifier"], name: "index_licenses_on_identifier"
    t.index ["uri"], name: "index_licenses_on_uri"
  end

  create_table "metadata_standards", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "rdamsc_id"
    t.string "uri"
    t.json "locations"
    t.json "related_entities"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "metadata_standards_research_outputs", force: :cascade do |t|
    t.bigint "metadata_standard_id"
    t.bigint "research_output_id"
    t.index ["metadata_standard_id"], name: "metadata_research_outputs_on_metadata"
    t.index ["research_output_id"], name: "metadata_research_outputs_on_ro"
  end

  create_table "notes", id: :integer, force: :cascade do |t|
    t.integer "user_id"
    t.text "text"
    t.boolean "archived", default: false, null: false
    t.integer "answer_id"
    t.integer "archived_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["answer_id"], name: "index_notes_on_answer_id"
    t.index ["user_id"], name: "fk_rails_7f2323ad43"
  end

  create_table "notification_acknowledgements", id: :integer, force: :cascade do |t|
    t.integer "user_id"
    t.integer "notification_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["notification_id"], name: "index_notification_acknowledgements_on_notification_id"
    t.index ["user_id"], name: "index_notification_acknowledgements_on_user_id"
  end

  create_table "notifications", id: :integer, force: :cascade do |t|
    t.integer "notification_type"
    t.string "title"
    t.integer "level"
    t.text "body"
    t.boolean "dismissable"
    t.date "starts_at"
    t.date "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "enabled", default: true
  end

  create_table "options_themes", id: false, force: :cascade do |t|
    t.integer "option_id", null: false
    t.integer "theme_id", null: false
    t.index ["option_id", "theme_id"], name: "index_options_themes_on_option_id_and_theme_id"
  end

  create_table "org_token_permissions", id: :integer, force: :cascade do |t|
    t.integer "org_id"
    t.integer "token_permission_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["org_id"], name: "index_org_token_permissions_on_org_id"
    t.index ["token_permission_type_id"], name: "fk_rails_2aa265f538"
  end

  create_table "orgs", id: :integer, force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.string "target_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_other", default: false, null: false
    t.integer "region_id"
    t.integer "language_id"
    t.string "logo_uid"
    t.string "logo_name"
    t.string "contact_email"
    t.integer "org_type", default: 0, null: false
    t.text "links"
    t.string "contact_name"
    t.boolean "feedback_enabled", default: false
    t.text "feedback_msg"
    t.boolean "managed", default: false, null: false
    t.string "helpdesk_email"
    t.index ["language_id"], name: "fk_rails_5640112cab"
    t.index ["region_id"], name: "fk_rails_5a6adf6bab"
  end

  create_table "perms", id: :integer, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "phases", id: :integer, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "number"
    t.integer "template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "modifiable"
    t.string "versionable_id", limit: 36
    t.index ["template_id"], name: "index_phases_on_template_id"
    t.index ["versionable_id"], name: "index_phases_on_versionable_id"
  end

  create_table "plans", id: :integer, force: :cascade do |t|
    t.string "title"
    t.integer "template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "identifier"
    t.text "description"
    t.integer "visibility", default: 3, null: false
    t.boolean "feedback_requested", default: false
    t.boolean "complete", default: false
    t.integer "org_id"
    t.integer "funder_id"
    t.integer "grant_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.bigint "research_domain_id"
    t.boolean "ethical_issues"
    t.text "ethical_issues_description"
    t.string "ethical_issues_report"
    t.integer "funding_status"
    t.integer "api_client_id"
    t.index ["funder_id"], name: "index_plans_on_funder_id"
    t.index ["grant_id"], name: "index_plans_on_grant_id"
    t.index ["org_id"], name: "index_plans_on_org_id"
    t.index ["research_domain_id"], name: "index_plans_on_research_domain_id"
    t.index ["template_id"], name: "index_plans_on_template_id"
  end

  create_table "plans_guidance_groups", id: :integer, force: :cascade do |t|
    t.integer "guidance_group_id"
    t.integer "plan_id"
    t.index ["guidance_group_id", "plan_id"], name: "index_plans_guidance_groups_on_guidance_group_id_and_plan_id"
    t.index ["plan_id"], name: "fk_rails_13d0671430"
  end

  create_table "prefs", id: :integer, force: :cascade do |t|
    t.text "settings"
    t.integer "user_id"
  end

  create_table "project_partners", id: :integer, force: :cascade do |t|
    t.integer "org_id"
    t.integer "project_id"
    t.boolean "leader_org"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "question_formats", id: :integer, force: :cascade do |t|
    t.string "title"
    t.text "description", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "option_based", default: false
    t.integer "formattype", default: 0
  end

  create_table "question_options", id: :integer, force: :cascade do |t|
    t.integer "question_id"
    t.text "text", limit: 16777215
    t.integer "number"
    t.boolean "is_default"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "versionable_id", limit: 36
    t.index ["question_id"], name: "index_question_options_on_question_id"
    t.index ["versionable_id"], name: "index_question_options_on_versionable_id"
  end

  create_table "question_options_themes", id: :integer, force: :cascade do |t|
    t.integer "question_option_id", null: false
    t.integer "theme_id", null: false
  end

  create_table "questions", id: :integer, force: :cascade do |t|
    t.text "text", limit: 16777215
    t.text "default_value"
    t.integer "number"
    t.integer "section_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "question_format_id"
    t.boolean "option_comment_display", default: true
    t.boolean "modifiable"
    t.string "versionable_id", limit: 36
    t.index ["question_format_id"], name: "fk_rails_4fbc38c8c7"
    t.index ["section_id"], name: "index_questions_on_section_id"
    t.index ["versionable_id"], name: "index_questions_on_versionable_id"
  end

  create_table "questions_themes", id: false, force: :cascade do |t|
    t.integer "question_id", null: false
    t.integer "theme_id", null: false
    t.index ["question_id"], name: "index_questions_themes_on_question_id"
    t.index ["theme_id"], name: "fk_rails_0489d5eeba"
  end

  create_table "regions", id: :integer, force: :cascade do |t|
    t.string "abbreviation"
    t.string "description"
    t.string "name"
    t.integer "super_region_id"
  end

  create_table "repositories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.string "homepage"
    t.string "contact"
    t.string "uri", null: false
    t.json "info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["homepage"], name: "index_repositories_on_homepage"
    t.index ["name"], name: "index_repositories_on_name"
    t.index ["uri"], name: "index_repositories_on_uri"
  end

  create_table "repositories_research_outputs", force: :cascade do |t|
    t.bigint "research_output_id"
    t.bigint "repository_id"
    t.index ["repository_id"], name: "index_repositories_research_outputs_on_repository_id"
    t.index ["research_output_id"], name: "index_repositories_research_outputs_on_research_output_id"
  end

  create_table "research_domains", force: :cascade do |t|
    t.string "identifier", null: false
    t.string "label", null: false
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_research_domains_on_parent_id"
  end

  create_table "research_outputs", force: :cascade do |t|
    t.integer "plan_id"
    t.integer "output_type", default: 3, null: false
    t.string "output_type_description"
    t.string "title", null: false
    t.string "abbreviation"
    t.integer "display_order"
    t.boolean "is_default"
    t.text "description"
    t.integer "access", default: 0, null: false
    t.datetime "release_date"
    t.boolean "personal_data"
    t.boolean "sensitive_data"
    t.bigint "byte_size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "license_id"
    t.index ["license_id"], name: "index_research_outputs_on_license_id"
    t.index ["output_type"], name: "index_research_outputs_on_output_type"
    t.index ["plan_id"], name: "index_research_outputs_on_plan_id"
  end

  create_table "roles", id: :integer, force: :cascade do |t|
    t.integer "user_id"
    t.integer "plan_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "access", default: 0, null: false
    t.boolean "active", default: true
    t.index ["plan_id"], name: "index_roles_on_plan_id"
    t.index ["user_id"], name: "index_roles_on_user_id"
  end

  create_table "sections", id: :integer, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "phase_id"
    t.boolean "modifiable"
    t.string "versionable_id", limit: 36
    t.index ["phase_id"], name: "index_sections_on_phase_id"
    t.index ["versionable_id"], name: "index_sections_on_versionable_id"
  end

  create_table "sessions", id: :integer, force: :cascade do |t|
    t.string "session_id", limit: 64, null: false
    t.text "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "settings", id: :integer, force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.integer "target_id", null: false
    t.string "target_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stats", id: :integer, force: :cascade do |t|
    t.bigint "count", default: 0
    t.date "date", null: false
    t.string "type", null: false
    t.integer "org_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "details"
    t.boolean "filtered", default: false
  end

  create_table "templates", id: :integer, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.boolean "published"
    t.integer "org_id"
    t.string "locale"
    t.boolean "is_default"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "version"
    t.integer "visibility"
    t.integer "customization_of"
    t.integer "family_id"
    t.boolean "archived"
    t.text "links"
    t.index ["family_id", "version"], name: "index_templates_on_family_id_and_version", unique: true
    t.index ["family_id"], name: "index_templates_on_family_id"
    t.index ["org_id", "family_id"], name: "template_organisation_dmptemplate_index"
    t.index ["org_id"], name: "index_templates_on_org_id"
  end

  create_table "themes", id: :integer, force: :cascade do |t|
    t.string "title"
    t.text "description", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale"
  end

  create_table "themes_in_guidance", id: false, force: :cascade do |t|
    t.integer "theme_id"
    t.integer "guidance_id"
    t.index ["guidance_id"], name: "index_themes_in_guidance_on_guidance_id"
    t.index ["theme_id"], name: "index_themes_in_guidance_on_theme_id"
  end

  create_table "token_permission_types", id: :integer, force: :cascade do |t|
    t.string "token_type"
    t.text "text_description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "trackers", id: :integer, force: :cascade do |t|
    t.integer "org_id"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["org_id"], name: "index_trackers_on_org_id"
  end

  create_table "ugent_logs", id: :integer, force: :cascade do |t|
    t.integer "item_id"
    t.string "item_type"
    t.string "event"
    t.text "whodunnit"
    t.integer "whodunnit_id"
    t.text "object"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event"], name: "index_ugent_logs_on_event"
    t.index ["item_type"], name: "index_ugent_logs_on_item_type"
    t.index ["whodunnit_id"], name: "index_ugent_logs_on_whodunnit_id"
  end

  create_table "ugent_org_domains", id: :integer, force: :cascade do |t|
    t.string "name", null: false
    t.integer "org_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_organisation_domains_on_name", unique: true
  end

  create_table "ugent_rest_users", id: :integer, force: :cascade do |t|
    t.string "code"
    t.string "token"
    t.integer "org_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ugent_wayfless_entities", id: :integer, force: :cascade do |t|
    t.string "name", null: false
    t.text "url", null: false
    t.integer "org_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_wayfless_entities_on_name", unique: true
    t.index ["url"], name: "index_wayfless_entities_on_url", unique: true, length: 255
  end

  create_table "users", id: :integer, force: :cascade do |t|
    t.string "firstname"
    t.string "surname"
    t.string "email", limit: 80, default: "", null: false
    t.integer "user_type_id"
    t.integer "user_status_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: ""
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.boolean "dmponline3"
    t.boolean "accept_terms"
    t.integer "org_id"
    t.string "other_organisation"
    t.string "api_token"
    t.integer "invited_by_id"
    t.string "invited_by_type"
    t.integer "language_id"
    t.string "recovery_email"
    t.boolean "active", default: true
    t.integer "department_id"
    t.datetime "last_api_access"
    t.index ["department_id"], name: "fk_rails_f29bf9cdf2"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["language_id"], name: "fk_rails_45f4f12508"
    t.index ["org_id"], name: "index_users_on_org_id"
  end

  create_table "users_perms", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "perm_id"
    t.index ["perm_id"], name: "fk_rails_457217c31c"
    t.index ["user_id"], name: "index_users_perms_on_user_id"
  end

  add_foreign_key "answers", "plans"
  add_foreign_key "answers", "questions"
  add_foreign_key "answers", "users"
  add_foreign_key "answers_question_options", "answers"
  add_foreign_key "answers_question_options", "question_options"
  add_foreign_key "conditions", "questions"
  add_foreign_key "guidance_groups", "orgs"
  add_foreign_key "guidances", "guidance_groups"
  add_foreign_key "notes", "answers"
  add_foreign_key "notes", "users"
  add_foreign_key "notification_acknowledgements", "notifications"
  add_foreign_key "notification_acknowledgements", "users"
  add_foreign_key "org_token_permissions", "orgs"
  add_foreign_key "org_token_permissions", "token_permission_types"
  add_foreign_key "orgs", "languages"
  add_foreign_key "orgs", "regions"
  add_foreign_key "phases", "templates"
  add_foreign_key "plans", "orgs"
  add_foreign_key "plans", "templates"
  add_foreign_key "plans_guidance_groups", "guidance_groups"
  add_foreign_key "plans_guidance_groups", "plans"
  add_foreign_key "question_options", "questions"
  add_foreign_key "questions", "question_formats"
  add_foreign_key "questions", "sections"
  add_foreign_key "questions_themes", "questions"
  add_foreign_key "questions_themes", "themes"
  add_foreign_key "research_domains", "research_domains", column: "parent_id"
  add_foreign_key "research_outputs", "licenses"
  add_foreign_key "roles", "plans"
  add_foreign_key "roles", "users"
  add_foreign_key "sections", "phases"
  add_foreign_key "templates", "orgs"
  add_foreign_key "themes_in_guidance", "guidances"
  add_foreign_key "themes_in_guidance", "themes"
  add_foreign_key "trackers", "orgs"
  add_foreign_key "users", "departments"
  add_foreign_key "users", "languages"
  add_foreign_key "users", "orgs"
  add_foreign_key "users_perms", "perms"
  add_foreign_key "users_perms", "users"
end
