#-- encoding: UTF-8

# This file written by BBM
# 16/07/2019

module API
  module V3
    module Diagrams
      class BubbleDiagramRepresenter < ::API::Decorators::Single
        include ::API::V3::Utilities::RoleHelper

        def initialize(params:, current_user:, global_role:)
          @name = params[:name]
          @project = params[:project]
          @current_user = current_user
          @global_role = global_role
        end

        property :data,
                 exec_context: :decorator,
                 getter: ->(*) {
                   result = []
                   projects = if @project and @project != '0'
                                Project.visible(current_user).where(id: @project)
                                  .or(Project.visible(current_user).where(parent_id: @project))
                                  .order(invest_amount: :desc).all
                              else
                                Project.visible(current_user).order(invest_amount: :desc).all
                              end
                   rmax = 0
                   xmax = 0
                   projects.each do |project|
                     exist = which_role(project, @current_user, @global_role)
                     if exist
                       x = project.parent_id || project.id
                       r = project.invest_amount.to_f
                       rmax = r if r > rmax
                       xmax = x if x > xmax
                       result << {x: x, y: 1, r: r, id: project.id}
                     end
                   end
                   result.each {|hash|
                     hash[:r] = (hash[:r] * 10 / rmax ).round
                     hash[:x] = hash[:x] * 3.8 / xmax
                   }
                   result
                 },
                 render_nil: true

        property :label,
                 exec_context: :decorator,
                 getter: ->(*) {
                   result = []
                   projects = if @project and @project != '0'
                                Project.visible(current_user).where(id: @project)
                                  .or(Project.visible(current_user).where(parent_id: @project))
                                  .order(invest_amount: :desc).all
                              else
                                Project.visible(current_user).order(invest_amount: :desc).all
                              end
                   projects.each do |project|
                     exist = which_role(project, @current_user, @global_role)
                     if exist
                       result << project.name + ' ' + project.invest_amount.to_s
                     end
                   end
                   result
                 },
                 render_nil: true

        def _type
          'BubbleDiagram'
        end
      end
    end
  end
end
