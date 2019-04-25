#-- encoding: UTF-8
# This file written by BBM
# 23/04/2019
class TypedRisksController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :find_typed_risk, only: [:edit, :update, :destroy]

  def index; end

  def edit; end

  def new
    @typed_risk = TypedRisk.new
  end

  def create
    @typed_risk = TypedRisk.new(permitted_params.typed_risk)

    if @typed_risk.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: 'index'
    else
      render action: 'new'
    end
  end

  def update
    if @typed_risk.update_attributes(permitted_params.typed_risk)
      flash[:notice] = l(:notice_successful_update)
      redirect_to typed_risks_path()
    else
      render action: 'edit'
    end
  end

  def destroy
    @typed_risk.destroy
    redirect_to action: 'index'
    return
  end

  protected

  def default_breadcrumb
    if action_name == 'index'
      t(:label_typed_risks)
    else
      ActionController::Base.helpers.link_to(t(:label_typed_risks), typed_risks_path)
    end
  end

  def show_local_breadcrumb
    true
  end

  def find_typed_risk
    @typed_risk = TypedRisk.find(params[:id])
  end
end
