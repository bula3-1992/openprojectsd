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

require 'redmine/menu_manager'

Redmine::MenuManager.map :top_menu do |menu|
  # projects menu will be added by
  # Redmine::MenuManager::TopMenuHelper#render_projects_top_menu_node

  menu.push :work_packages_execution,
            { controller: '/work_packages', project_id: nil, state: nil, plan_type: 'execution', action: 'index' },
            context: :modules,
            caption: I18n.t('label_work_package_plural'),
            if: Proc.new {
              (User.current.logged? || !Setting.login_required?) &&
                User.current.allowed_to?(:view_work_packages, nil, global: true)
            }

  menu.push :work_packages_planning,
            { controller: '/work_packages', project_id: nil, state: nil, plan_type: 'planning', action: 'index' },
            context: :modules,
            caption: I18n.t('label_plan_stage_package_plural'),
            if: Proc.new {
              (User.current.logged? || !Setting.login_required?) &&
                User.current.allowed_to?(:view_work_packages, nil, global: true)
            }

  menu.push :news,
            { controller: '/news', project_id: nil, action: 'index' },
            context: :modules,
            if: Proc.new {
              (User.current.logged? || !Setting.login_required?) &&
                User.current.allowed_to?(:view_news, nil, global: true)
            }
  menu.push :time_sheet,
            { controller: '/timelog', project_id: nil, action: 'index' },
            context: :modules,
            caption: I18n.t('label_time_sheet_menu'),
            if: Proc.new {
              (User.current.logged? || !Setting.login_required?) &&
                User.current.allowed_to?(:view_time_entries, nil, global: true)
            }
  menu.push :help, OpenProject::Static::Links.help_link,
            last: true,
            caption: '',
            icon: 'icon5 icon-help',
            html: { accesskey: OpenProject::AccessKeys.key_for(:help),
                    title: I18n.t('label_help'),
                    class: 'menu-item--help',
                    target: '_blank' }
end

Redmine::MenuManager.map :account_menu do |menu|
  menu.push :my_page,
            { controller: '/my', action: 'page' },
            if: Proc.new { User.current.logged? }
  menu.push :my_account,
            { controller: '/my', action: 'account' },
            if: Proc.new { User.current.logged? }
  menu.push :administration,
            { controller: '/users', action: 'index' },
            if: Proc.new { User.current.admin?||User.current.detect_project_office_coordinator?||User.current.detect_project_administrator? }
  # menu.push :coordination,
  #           { controller: '/projects', action: 'index' },
  #           if: Proc.new { User.current.detect_project_office_coordinator? }
  menu.push :logout, :signout_path,
            if: Proc.new { User.current.logged? }
end

Redmine::MenuManager.map :application_menu do |menu|
  menu.push :work_packages_query_select,
            { controller: '/work_packages', action: 'index' },
            parent: :work_packages,
            partial: 'work_packages/menu_query_select',
            last: true
end

Redmine::MenuManager.map :my_menu do |menu|
  menu_push = menu.push :account,
                        { controller: '/my', action: 'account' },
                        caption: :label_profile,
                        icon: 'icon2 icon-user'
  menu_push
  menu.push :settings,
            { controller: '/my', action: 'settings' },
            caption: :label_settings,
            icon: 'icon2 icon-settings2'
  menu.push :password,
            { controller: '/my', action: 'password' },
            caption: :button_change_password,
            if: Proc.new { User.current.change_password_allowed? },
            icon: 'icon2 icon-locked'
  menu.push :access_token,
            { controller: '/my', action: 'access_token' },
            caption: I18n.t('my_account.access_tokens.access_token'),
            icon: 'icon2 icon-key'
  menu.push :mail_notifications,
            { controller: '/my', action: 'mail_notifications' },
            caption: I18n.t('activerecord.attributes.user.mail_notification'),
            icon: 'icon2 icon-news'
  menu.push :pop_up_notifications,
            { controller: '/my', action: 'pop_up_notifications' },
            caption: I18n.t('activerecord.attributes.user.pop_up_notification'),
            icon: 'icon2 icon-news'
  menu.push :delete_account, :deletion_info_path,
            caption: I18n.t('account.delete'),
            param: :user_id,
            if: Proc.new { Setting.users_deletable_by_self? },
            last: :delete_account,
            icon: 'icon2 icon-delete'
end

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :users,
            { controller: '/users' },
            caption: :label_user_plural,
            icon: 'icon2 icon-user',
            if: Proc.new { User.current.admin?||User.current.detect_project_office_coordinator?||User.current.detect_project_administrator?}


  menu.push :roles,
            { controller: '/roles' },
            caption: :label_role_and_permissions,
            icon: 'icon2 icon-settings',
            if: Proc.new { User.current.admin?}

  ##zbd(
  menu.push :contracts,
            { controller: '/contracts' },
            icon: 'icon2 icon-enumerations',
            if: Proc.new { User.current.admin?||User.current.detect_project_office_coordinator?||User.current.detect_project_administrator? }
  # )
  menu.push :system_catalogs,
            {},
            caption: :label_system_catalogs,
            icon: 'icon2 icon-types',
            if: Proc.new { User.current.admin?}

  menu.push :groups,
            { controller: '/groups' },
            caption: :label_group_plural,
            icon: 'icon2 icon-group',
            parent: :system_catalogs

  menu.push :statuses,
            { controller: '/statuses' },
            caption: :label_work_package_status_plural,
            icon: 'icon2 icon-flag',
            html: { class: 'statuses' },
            parent: :system_catalogs

  menu.push :types,
            { controller: '/types' },
            caption: :label_work_package_types,
            icon: 'icon2 icon-types',
            parent: :system_catalogs

  menu.push :workflows,
            { controller: '/workflows', action: 'edit' },
            caption: Proc.new { Workflow.model_name.human },
            icon: 'icon2 icon-workflow',
            if: Proc.new { User.current.admin?||User.current.detect_project_office_coordinator?}

  menu.push :custom_fields,
            { controller: '/custom_fields' },
            caption: :label_custom_field_plural,
            icon: 'icon2 icon-custom-fields',
            html: { class: 'custom_fields' },
            if: Proc.new { User.current.admin?||User.current.detect_project_office_coordinator? }
  #knm(
  menu.push :head_performance_indicator_values,
            {controller: '/head_performance_indicator_values'},
            icon: 'icon2 icon-enumerations',
            if: Proc.new { User.current.admin?||User.current.detect_project_office_coordinator? }
  menu.push :production_calendars,
            {controller: '/production_calendars'},
            icon: 'icon2 icon-calendar',
            if: Proc.new { User.current.admin?||User.current.detect_project_office_coordinator? }
  menu.push :strategic_map,
            {controller: 'strategic_map'},
            icon: 'icon2 icon-organization',
            if: Proc.new { User.current.admin?||User.current.detect_project_office_coordinator? }
  # )
  #bbm(
  menu.push :typed_risks,
            { controller: '/typed_risks' },
            icon: 'icon2 icon-risks',
            if: Proc.new { User.current.admin?||User.current.detect_project_office_coordinator? }

  menu.push :control_levels,
            { controller: '/control_levels' },
            icon: 'icon2 icon-control-levels',
            if: Proc.new { User.current.admin?||User.current.detect_project_office_coordinator? }
  # )
  # +tan 2019.04.25
  # menu.push :positions,
  #           { controller: '/positions' },
  #           icon: 'icon2 icon-risks'

  menu.push :org_settings,
            { },
            caption: :label_org_settings,
            icon: 'icon2 icon-organization',
            if: Proc.new { User.current.admin?||User.current.detect_project_office_coordinator? ||User.current.detect_project_administrator?}
  menu.push :org_iogv,
            {controller: '/org_settings', action: 'iogv' },
            icon: 'icon2 icon-organization',
            caption: :label_iogv,
            parent: :org_settings

  menu.push :org_municipalities,
            {controller: '/org_settings', action: 'municipalities' },
            icon: 'icon2 icon-organization',
            caption: :label_municipalities,
            parent: :org_settings

  menu.push :org_counterparties,
            {controller: '/org_settings', action: 'counterparties' },
            icon: 'icon2 icon-organization',
            caption: :label_counterparties,
            parent: :org_settings

  menu.push :org_positions,
            {controller: '/org_settings', action: 'positions' },
            icon: 'icon2 icon-position',
            caption: :label_positions,
            parent: :org_settings
  # -tan

  #+-tan 2019.06.24
  # menu.push :custom_actions,
  #           { controller: '/custom_actions' },
  #           caption: :'custom_actions.plural',
  #           icon: 'icon2 icon-play'

  menu.push :attribute_help_texts,
            { controller: '/attribute_help_texts' },
            caption: :'attribute_help_texts.label_plural',
            icon: 'icon2 icon-help2',
            if: Proc.new {
              EnterpriseToken.allows_to?(:attribute_help_texts)&&User.current.admin?
            }

  menu.push :enumerations,
            { controller: '/enumerations' },
            icon: 'icon2 icon-enumerations',
            if: Proc.new { User.current.admin? ||User.current.detect_project_office_coordinator?}

  menu.push :settings,
            { controller: '/settings' },
            caption: :label_system_settings,
            if: Proc.new { User.current.admin?},
            icon: 'icon2 icon-settings2'

  menu.push :additional_settings,
            {},
            caption: :label_additional_settings,
            icon: 'icon22 icon-settings2',
            if: Proc.new { User.current.admin?}

  menu.push :ldap_authentication,
            { controller: '/ldap_auth_sources', action: 'index' },
            html: { class: 'server_authentication' },
            icon: 'icon2 icon-flag',
            parent: :additional_settings,
            if: proc { !OpenProject::Configuration.disable_password_login? }

  menu.push :colors,
            { controller: '/colors', action: 'index' },
            caption:    :'timelines.admin_menu.colors',
            icon: 'icon2 icon-status',
            parent: :additional_settings
  #+-tan 2019.06.24
  # menu.push :oauth_applications,
  #           { controller: '/oauth/applications', action: 'index' },
  #           html: { class: 'oauth_applications' },
  #           icon: 'icon2 icon-key'
  #
  # menu.push :announcements,
  #           { controller: '/announcements', action: 'edit' },
  #           caption: 'Announcement',
  #           icon: 'icon2 icon-news'

  # menu.push :plugins,
  #           { controller: '/admin', action: 'plugins' },
  #           last: true,
  #           icon: 'icon2 icon-plugins'

  menu.push :info,
            { controller: '/admin', action: 'info' },
            caption: :label_information_plural,
            last: true,
            icon: 'icon2 icon-info1',
            if: Proc.new { User.current.admin?}
  #knm(
  menu.push :interactive_map,
            {controller: '/interactive_map', action: 'index'},
            caption: :label_interactive_map,
            icon: 'icon2 icon-map',
            if: Proc.new { User.current.admin?||User.current.detect_project_office_coordinator? }
  menu.push :nat_fed_gov,
            {},
            caption: :label_national_projects_government_programs,
            #if: Proc.new { |p| p.module_enabled?('stages') },
            icon: 'icon2 icon-national',
            if: Proc.new { User.current.admin?||User.current.detect_project_office_coordinator? }
  menu.push :national_projects,
            {controller: '/national_projects', action: 'index'},
            caption: :label_national_projects,
            icon: 'icon2 icon-national',
            parent: :nat_fed_gov
  menu.push :government_programs,
            {controller: '/national_projects', action: 'government_programs'},
            caption: :label_government_programs,
            icon: 'icon2 icon-national',
            parent: :nat_fed_gov
  # )
  # +-tan 2019.06.24
  # menu.push :custom_style,
  #           { controller: '/custom_styles', action: 'show' },
  #           caption:    :label_custom_style,
  #           icon: 'icon2 icon-design'



  # +-tan 2019.06.24
  # menu.push :enterprise,
  #           { controller: '/enterprises', action: 'show' },
  #           caption:    :label_enterprise_edition,
  #           icon: 'icon2 icon-headset',
  #           if: proc { OpenProject::Configuration.ee_manager_visible? }
end

# Redmine::MenuManager.map :coordinator_menu do |menu|
#
#   menu.push :types,
#             { controller: '/types' },
#             caption: :label_work_package_types,
#             icon: 'icon2 icon-types'
#   menu.push :groups,
#             { controller: '/groups' },
#             caption: :label_group_plural,
#             icon: 'icon2 icon-group'
# end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push :overview,
            { controller: '/projects', action: 'show' },
            icon: 'icon2 icon-info1'
  #xcc(
  menu.push :targets,
            { controller: '/targets', action: 'index' },
            param: :project_id,
            caption: :label_target,
            if: Proc.new { |p| p.module_enabled?('targets') },
            icon: 'icon2 icon-target',
            parent: :all_plans
  # )


  ##zbd(
  menu.push :stages,
            { controller: '/stages', action: 'show' },
            param: :project_id,
            caption: :label_stages,
            if: Proc.new { |p| p.module_enabled?('stages') },
            icon: 'icon2 icon-etap',
            parent: :analyze
  # )

  # +tan 2019.07.16
  # menu.push :all_plans,
  #             { controller: '/stages', action: 'show' },
  #             param: :project_id,
  #             caption: :label_all_plans,
  #             #if: Proc.new { |p| p.module_enabled?('stages') },
  #             icon: 'icon2 icon-info1'
  menu.push :analyze,
            {},
            caption: :label_stage_analysis,
            #if: Proc.new { |p| p.module_enabled?('stages') },
            icon: 'icon2 icon-analyze'
  menu.push :communictaions,
            {},
            param: :project_id,
            caption: :label_communictaions,
            #if: Proc.new { |p| p.module_enabled?('stages') },
            icon: 'icon2 icon-communication'
  menu.push :resources,
            {},
            param: :project_id,
            caption: :label_resources,
            #after: :communictaion,
            #if: Proc.new { |p| p.module_enabled?('stages') },
            icon: 'icon2 icon-resource'
  menu.push :control,
            {},
            param: :project_id,
            caption: :label_control,
            #after: :communictaion,
            #if: Proc.new { |p| p.module_enabled?('stages') },
            icon: 'icon2 icon-checkmark'
  #нехорошо из модуля переносить, но что делать TODO: need fix
  # menu.push :meetings,
  #           { controller: '/meetings', action: 'index' },
  #           caption: :project_module_meetings,
  #           param: :project_id,
  #           icon: 'icon2 icon-meetings',
  #           parent: :resources #+-tan
  #-tan 2019.07.16
  menu.push :activity,
            { controller: '/activities', action: 'index' },
            param: :project_id,
            if: Proc.new { |p| p.module_enabled?('activity') },
            parent: :control,
            icon: 'icon2 icon-checkmark'

  menu.push :roadmap,
            { controller: '/versions', action: 'index' },
            param: :project_id,
            if: Proc.new { |p| p.shared_versions.any? },
            icon: 'icon2 icon-roadmap'

  menu.push :work_packages_execution,
            { controller: '/work_packages', state: nil, plan_type: 'execution', action: 'index' },
            param: :project_id,
            caption: :label_work_package_plural,
            icon: 'icon2 icon-view-timeline',
            html: {
              id: 'main-menu-work-packages',
              :'wp-query-menu' => 'wp-query-menu'
            }

   menu.push :work_packages_execution_query_select,
             { controller: '/work_packages', state: nil, plan_type: 'execution', action: 'index' },
             param: :project_id,
             parent: :work_packages_execution,
             partial: 'work_packages/menu_query_select',
             last: true,
             caption: :label_all_open_wps

  #bbm(
  # menu.push :work_packages_planning,
  #           { controller: '/work_packages', state: nil, plan_type: 'planning', action: 'index' },
  #           param: :project_id,
  #           caption: :label_plan_stage_package_plural,
  #           icon: 'icon2 icon-view-timeline',
  #           html: {
  #             id: 'main-menu-plan-packages',
  #             :'psp-query-menu' => 'psp-query-menu'
  #           }
  #
  # menu.push :work_packages_planning_query_select,
  #           { controller: '/work_packages', state: nil, plan_type: 'planning', action: 'index' },
  #           param: :project_id,
  #           parent: :work_packages_planning,
  #           partial: 'work_packages/menu_query_select_planning',
  #           last: true,
  #           caption: :label_all_open_wps
  # )

  menu.push :calendar,
            { controller: '/work_packages/calendars', action: 'index' },
            param: :project_id,
            caption: :label_calendar,
            parent: :control,
            icon: 'icon2 icon-calendar'

  menu.push :news,
            { controller: '/news', action: 'index' },
            param: :project_id,
            caption: :label_news_plural,
            icon: 'icon2 icon-news',
            parent: :communictaions

  menu.push :boards,
            { controller: '/boards', action: 'index', id: nil },
            param: :project_id,
            if: Proc.new { |p| p.boards.any? },
            caption: :label_board_plural,
            icon: 'icon2 icon-ticket-note'

  #+-tan 2019.07.16
  # menu.push :repository,
  #           { controller: '/repositories', action: 'show' },
  #           param: :project_id,
  #           if: Proc.new { |p| p.repository && !p.repository.new_record? },
  #           icon: 'icon2 icon-folder-open'

  # Wiki menu items are added by WikiMenuItemHelper

  menu.push :time_entries,
            { controller: '/timelog', action: 'index' },
            param: :project_id,
            if: -> (project) { User.current.allowed_to?(:view_time_entries, project) },
            caption: :label_time_sheet_menu,
            icon: 'icon2 icon-cost-reports'

  menu.push :members,
            { controller: '/members', action: 'index' },
            param: :project_id,
            caption: :label_member_plural,
            icon: 'icon2 icon-group',
            parent: :resources

  #bbm(
  menu.push :project_risks,
            { controller: '/project_risks', action: 'index' },
            param: :project_id,
            if: Proc.new { |p| p.module_enabled?('project_risks') },
            icon: 'icon2 icon-risks',
            parent: :analyze
  # )
  #
  # + tan 2019/07/16
  menu.push :reports,
            {},
            param: :project_id,
            caption: :label_reports,
            icon: 'icon2 icon-info1'

  menu.push :report_progress_project,
            {controller: '/report_progress_project', action: 'index' },
            param: :project_id,
            caption: :label_report_progress_project,
            icon: 'icon2 icon-info1',
            parent: :reports

  menu.push :additional,
            {},
            param: :project_id,
            caption: :ladel_additional,
            #if: Proc.new { |p| p.module_enabled?('stages') },
            icon: 'icon2 icon-additional'
  #-tan

  #xcc(
  menu.push :arbitary_objects,
            { controller: '/arbitary_objects', action: 'index' },
            param: :project_id,
            caption: :label_arbitary_objects,
            if: Proc.new { |p| p.module_enabled?('arbitary_objects') },
            icon: 'icon2 icon-info1',
            parent: :additional

  menu.push :agreements,
            { controller: '/agreements', action: 'index' },
            param: :project_id,
            caption: :label_agreements,
            if: Proc.new { |p| p.module_enabled?('agreements') },
            parent: :control,
            icon: 'icon2 icon-info1'


  # )



  menu.push :settings,
            { controller: '/project_settings', action: 'show' },
            caption: :label_project_settings,
            last: true,
            icon: 'icon2 icon-settings2'
end

Redmine::MenuManager.map :dashboard_menu do |menu|
  menu.push :rabocii_stol,
            '',
            caption: 'Рабочий стол',
            icon: 'icon2 icon-info1'
  menu.push :kontrolnie_tochki,
            '',
            caption: 'Контрольные точки',
            icon: 'icon2 icon-roadmap'
  menu.push :riski_i_problemy,
            '',
            caption: 'Риски и проблемы',
            icon: 'icon2 icon-risks'
  menu.push :ispolnenie_pokazatelei,
            '',
            caption: 'Исполнение показателей',
            icon: 'icon2 icon-report'
  menu.push :ispolnenie_budzheta,
            '',
            caption: 'Исполнение бюджета',
            icon: 'icon2 icon-cost-reports'
  menu.push :kpi,
            '',
            caption: 'KPI',
            icon: 'icon2 icon-control-levels'
  menu.push :elektronnyi_protokol,
            '',
            caption: 'Электронный протокол',
            icon: 'icon2 icon-enumerations'
  menu.push :obsuzhdeniya,
            '',
            caption: 'Обсуждения',
            icon: 'icon2 icon-ticket-note'
  menu.push :ocenka_deyatelnosti,
            '',
            caption: 'Оценка деятельности',
            icon: 'icon2 icon-enumerations'
  menu.push :municipalitet,
            '',
            caption: 'Муниципалитет',
            icon: 'icon2 icon-organization'
end
