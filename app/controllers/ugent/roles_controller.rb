# frozen_string_literal: true

class Ugent::RolesController < ApplicationController

  before_action :authenticate_user!

  def update_role_with_contributor

    role_params = params.require(:role).permit(:id)

    @role = Role.find(role_params[:id])

    authorize @role.plan

    # no boxes checked, no parameters sent
    params[:contributor] ||= Hash[Contributor.roles.map { |cr| [cr, 0] }]

    contributor_params = params.require(:contributor)
                               .permit(*Contributor.roles)

    contributor = Contributor.where(email: @role.user.email, plan_id: @role.plan_id)
                             .first()

    if contributor.nil?

      contributor = Contributor.new(email: @role.user.email, plan_id: @role.plan_id)

    end

    contributor.roles = 0

    Contributor.roles.each do |contributor_access|
      if contributor_params.key?(contributor_access.to_s)
        contributor.send("#{contributor_access}=", contributor_params[contributor_access])
      end
    end

    if contributor.roles == 0

      contributor.destroy if contributor.persisted?
      render json: {
        code: 1,
        msg: _("Successfully cleared contribution for %{email}.") % { email: @role.user.email }
      }
      return

    end

    contributor.update_from_user(@role.user)

    if contributor.save

      render json: {
        code: 1,
        msg: _("Successfully changed contribution for %{email} to: %{roles}") % {
          email: @role.user.email,
          roles: Contributor.roles
                            .select { |rk| contributor.send(rk) }
                            .map { |rk| ContributorPresenter.role_symbol_to_string(symbol: rk) }
                            .to_sentence
        }
      }

    else

      render json: {
        code: 0,
        msg: contributor.errors
                        .full_messages
                        .join("<br>")
      }

    end

  end

end
