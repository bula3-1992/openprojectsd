#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json'
require 'roar/json/collection'
require 'roar/json/hal'

module API
  module V3
    module NationalProjects
      class NationalProjectCollectionRepresenter < ::API::Decorators::UnpaginatedCollection
        include ::API::V3::Utilities::RoleHelper

        element_decorator ::API::V3::NationalProjects::NationalProjectRepresenter

        def initialize(models,
                       params,
                       self_link,
                       current_user:,
                       global_role:)
          super(models,
                self_link,
                current_user: current_user)
          @current_user = current_user
          @global_role = global_role
          @param_context = params[:context]
          @raion = params[:raion]
          @project = params[:project]
        end

        collection :elements,
                   getter: ->(*) {
                     @elements = []
                     defilter
                     render_tree(represented, nil)
                     # Rails.logger.info('repr: ' + represented.to_json)
                     # Rails.logger.info(@elements ? @elements.size() : 'empty mat proj')
                     @elements
                   },
                   exec_context: :decorator,
                   embedded: true

        private

        def defilter
          @ids = [0]
          projects = [0]
          if @project
            projects << @project
          else
            Project.where(type: 'project').visible_by(@current_user).each do |project|
              exist = which_role(project, @current_user, @global_role)
              if exist and project.visible? @current_user
                projects << project.id
              end
            end
          end
          case @param_context
          when 'desktop'
            meropriyatie = Type.find_by name: I18n.t(:default_type_task)
            kt = Type.find_by name: I18n.t(:default_type_milestone)
            if @raion
              rprojects = Raion.projects_by_id(@raion, projects).map { |p| p.id }
              records_array = ActiveRecord::Base.connection.execute <<~SQL
                select p.id, p.national_project_id, p.federal_project_id, p1.preds, p1.prosr, p1.riski, p2.ispolneno, p2.all_wps from
                    (select * from projects where id in (#{rprojects.join(",")})) as p
                left join
                    (select project_id, sum(preds) as preds, sum(prosr) as prosr, sum(riski) as riski
                    from (
                             select wp.project_id,
                                    case when wp.days_to_due >= 0 and wp.days_to_due <= 14 and wp.raion_id = #{@raion} and wp.type_id = #{meropriyatie.id} and wp.ispolneno = false then 1 else 0 end as preds,
                                    case when wp.days_to_due < 0 and wp.raion_id = #{@raion} and wp.type_id = #{kt.id} and wp.ispolneno = false then 1 else 0 end as prosr,
                                    case when wp.raion_id = #{@raion} then wp.created_problem_count else 0 end as riski
                             from v_work_package_ispoln_stat as wp
                             where wp.raion_id = #{@raion}
                         ) as slice
                    group by project_id) as p1
                on p.id = p1.project_id
                left join
                    (select project_id, sum(ispolneno) as ispolneno, sum(all_work_packages) as all_wps
                    from v_project_ispoln_stat
                    group by project_id) as p2
                on p.id = p2.project_id
              SQL
            else
              records_array = ActiveRecord::Base.connection.execute <<~SQL
                select p.id, p.national_project_id, p.federal_project_id, p1.preds, p1.prosr, p1.riski, p2.ispolneno, p2.all_wps from
                    (select * from projects where id in (#{projects.join(",")})) as p
                left join
                    (select project_id, sum(preds) as preds, sum(prosr) as prosr, sum(created_problem_count) as riski
                    from (
                             select wp.project_id,
                                    case when wp.days_to_due >= 0 and wp.days_to_due <= 14 and wp.type_id = #{meropriyatie.id} and wp.ispolneno = false then 1 else 0 end as preds,
                                    case when wp.days_to_due < 0 and wp.type_id = #{kt.id} and wp.ispolneno = false then 1 else 0 end as prosr,
                                    wp.created_problem_count
                             from v_work_package_ispoln_stat as wp
                         ) as slice
                    group by project_id) as p1
                on p.id = p1.project_id
                left join
                    (select project_id, sum(ispolneno) as ispolneno, sum(all_work_packages) as all_wps
                    from v_project_ispoln_stat
                    group by project_id) as p2
                on p.id = p2.project_id
              SQL
            end
            records_array.map do |pr|
              if pr['federal_project_id']
                @ids << pr['federal_project_id']
              end
              if pr['national_project_id']
                @ids << pr['national_project_id']
              end
            end
          when 'protocol'
            temp_ids = [0]
            temp_ids += MeetingProtocol
                        .joins(:meeting)
                        .where("meetings.project_id in (" + projects.join(",") + ")")
                        .select("meetings.project_id").map(&:project_id).uniq
            Project.where("id in (" + temp_ids.join(",") + ")").map do |pr|
              if pr.federal_project
                @ids << pr.federal_project.id
              end
              if pr.national_project
                @ids << pr.national_project.id
              end
            end
          else
            NationalProject.all.map do |np|
              @ids << np.id
            end
          end
        end

        def render_tree(tree, pid)
          puts @param_context
          represented.map do |el|
            if @ids.include? el.id
              # Rails.logger.info("render_tree: #{el.id} PID: #{pid} el.parent_id= #{el.parent_id}")
              # Rails.logger.info('current_user: ' + @current_user.name + ' @global_role: ' + @global_role.to_s)
              if el.parent_id == pid
                exist = nil
                if pid
                  exist = which_roles(el.projects_federal, @current_user)
                  # el.projects_federal.map do |project|
                  # exist ||= which_role(project, @current_user, @global_role)
                  # Rails.logger.info('project:' + project.id.id.to_s + 'roles' + which_role(project, @current_user, @global_role).to_json())
                  # end
                else
                  # exist = nil
                  exist = which_roles(el.projects, @current_user)
                  # el.projects.map do |project|
                  #   exist ||= which_role(project, @current_user, @global_role)
                  #   #Rails.logger.info('project:' + project.id.to_s + 'roles' + which_role(project, @current_user, @global_role).to_json())
                  # end
                end
                # Rails.logger.info("exist#{exist} render_tree: #{el.id} PID: #{pid} el.parent_id= #{el.parent_id}")
                unless exist
                  next
                end

                @elements << element_decorator.create(el, current_user: current_user)
                render_tree(tree, el.id)
              end
            end
          end
        end
      end
    end
  end
end
