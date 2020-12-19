# frozen_string_literal: true

class Ugent::SelectableUserController < ApplicationController

  before_action :require_authentication

  def edit
    render :edit
  end

  def update
    user_params = params.require(:selectable_user).permit(:id)

    user_id = user_params[:id].to_i

    user_index = @selectable_users.index { |u| u.id == user_id }

    if user_index

      session.delete(:selectable_user_ids)
      sign_in @selectable_users[user_index]
      redirect_to root_path

    else

      redirect_to edit_selectable_user_path, alert: "Invalid user selected"

    end
  end

  private

  def require_authentication
    if user_signed_in?

      redirect_to root_path, alert: "Already logged in"

    elsif !session[:selectable_user_ids].is_a?(Array)

      redirect_to root_path, alert: "Not authenticated"

    else

      @selectable_users = session[:selectable_user_ids].map { |user_id| User.find(user_id) }

    end
  end

end
