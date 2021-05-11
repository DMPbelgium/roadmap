# frozen_string_literal: true

class Ugent::Legacy::ProjectsController < ApplicationController

  def show
    redirect_to plan_url(id: params[:id])
  end

  def index
    redirect_to plans_url()
  end

end
