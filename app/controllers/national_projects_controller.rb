class NationalProjectsController < ApplicationController
  helper :sort
  layout 'admin'
  before_action :require_coordinator
  before_action :find_national_project, only: [:edit, :update, :destroy]
  # before_action :authorize_global, only: [:government_programs, :show, :index, :edit, :update, :destroy, :new]
  include SortHelper
  include ::IconsHelper
  include ::ColorsHelper
  include TargetsHelper
  def index
    sort_columns = {'id' => "#{NationalProject.table_name}.id",
                    'name'=>"#{NationalProject.table_name}.name",
                    'leader'=>"#{NationalProject.table_name}.leader",
                    'curator'=>"#{NationalProject.table_name}.curator",
                    'start_date'=>"#{NationalProject.table_name}.start_date",
                    'due_date'=>"#{NationalProject.table_name}.due_date"
    }
    sort_init [['parent_id', 'asc'],['id', 'asc']]
    sort_update sort_columns
    @national_projects = NationalProject.order(sort_clause)
  end
  def government_programs
    sort_columns = {'id' => "#{NationalProject.table_name}.id",
                    'name'=>"#{NationalProject.table_name}.name",
                    'description'=>"#{NationalProject.table_name}.description",
                    'leader'=>"#{NationalProject.table_name}.leader",
                    'curator'=>"#{NationalProject.table_name}.curator",
                    'start_date'=>"#{NationalProject.table_name}.start_date",
                    'due_date'=>"#{NationalProject.table_name}.due_date"
    }
    sort_init [['parent_id', 'asc'],['id', 'asc']]
    sort_update sort_columns
    @national_projects = NationalProject.order(sort_clause)
  end
  def show
    sort_columns = {'id' => "#{NationalProject.table_name}.id",
                    'name'=>"#{NationalProject.table_name}.name",
                    'description'=>"#{NationalProject.table_name}.description",
                    'leader'=>"#{NationalProject.table_name}.leader",
                    'curator'=>"#{NationalProject.table_name}.curator",
                    'start_date'=>"#{NationalProject.table_name}.start_date",
                    'due_date'=>"#{NationalProject.table_name}.due_date"
    }
    sort_init [['parent_id', 'asc'],['id', 'asc']]
    sort_update sort_columns
    @national_projects = NationalProject.order(sort_clause)
  end

  def edit
      @national_project = NationalProject
                      .find(params[:id])
  end

  def update
    if @national_project.update_attributes(permitted_params.national_project)
      flash[:notice] = l(:notice_successful_update)
      redirect_to national_projects_path
    else
      render action: 'edit'
    end
  end

  def new
    @national_project = NationalProject.new
  end

  def new_government
    @national_project = NationalProject.new
    @national_project.type="Government"
  end

  def create
    @national_project = NationalProject.new(permitted_params.national_project)
    if params["national_project"]["parent_id"] == ""
      @national_project.type="National"
    else
      @national_project.type="Federal"
    end
    if params["national_project"]["type"] == "Government"
      @national_project.type=params["national_project"]["type"]
    end
    if @national_project.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to national_projects_path
    else
      render action: 'new'
    end
  end

  def destroy
    if @national_project.type === "National"
      del=0
      NationalProject.where(type: "Federal").each do |national_project|
        if national_project.parent_id === @national_project.id
          # national_project.parent_id = null
          del=del+1
          # national_project.destroy
        end
      end
      if del==0
        @national_project.destroy
      else
        flash.now[:error] = l(:notice_project_not_deleted)
        redirect_to action: 'index'
      end
    else
    @national_project.destroy
    redirect_to action: 'index'
    end
    nil
  end

  def default_breadcrumb
    if action_name == 'index'
      t(:label_national_projects)
    elsif action_name == 'government_programs'
      t(:label_government_programs)
    elsif action_name == 'new_government'
      ActionController::Base.helpers.link_to(t(:label_government_programs), government_programs_national_projects_path)
    else
      ActionController::Base.helpers.link_to(t(:label_national_projects), national_projects_path)
    end
  end

  def show_local_breadcrumb
    true
  end

  def find_national_project
    @national_project = NationalProject.find(params[:id])
  end

end
