# frozen_string_literal: true

Rails.application.routes.draw do

  get "selectable_user/edit", controller: "ugent/selectable_user", action: :edit, as: :edit_selectable_user
  post "selectable_user", controller: "ugent/selectable_user", action: :update, as: :update_selectable_user

  get "switch_user/edit", controller: "ugent/switch_user", action: :edit, as: :edit_switch_user
  post "switch_user", controller: "ugent/switch_user", action: :update, as: :update_switch_user

=begin TODO
  get "/internal/exports/v01/organisations/:organisation/:name.json",
    :to => "internal/exports#show_link",
    :organisation => /[a-zA-Z0-9_\-]+/,
    :name => /[a-zA-Z0-9_\-\.:]+/

  get "/internal/exports/v01/organisations/:organisation/:year/:month/:name.json",
    :to => "internal/exports#show_file",
    :organisation => /[a-zA-Z0-9_\-]+/,
    :year => /\d{4}/,
    :month => /\d{2}/,
    :name => /[a-zA-Z0-9_\-\.:]+/
=end
end
