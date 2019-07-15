#-- encoding: UTF-8

#+-tan 2019.04.25

class PlanUploadersController < ApplicationController
  require 'roo'
  require 'date'
  require 'translit'

  RUSSIAN_MONTH_NAMES_SUBSTITUTION = {
    'январь' => 'jan', 'февраль' => 'feb', 'март' => 'mar',
    'апрель' => 'apr', 'май' => 'may', 'июнь' => 'jun',
    'июль' => 'jul', 'август' => 'aug', 'сентябрь' => 'sep',
    'октябрь' => 'oct', 'ноябрь' => 'nov', 'декабрь' => 'dec'
  }.freeze

  def index
    @plan_uploaders = PlanUploader.all
  end

  def new
    @project = Project.find(params[:project_id])
    @plan_uploader = PlanUploader.new
  end

  def create
    @plan_uploader = PlanUploader.new(permitted_params.plan_uploader)
    @first_row_num = params[:first_row_num]

    if @plan_uploader.save
      # puts @plan_uploader.name.store_path
      # if @plan_uploader.status
      # load_eb
      # else
      load
      # end
      # render "new"
      redirect_to project_stages_path, notice: "Данные загружены."
    else
      render "new"
    end
  end

  def destroy
    # @plan_uploaders = Resume.find(params[:id])
    # @plan_uploaders.destroy
    # redirect_to resumes_path, notice:  "The resume #{@resume.name} has been deleted."
  end

  protected

  def load

    prepare_roo
    filename = Rails.root.join('public', @plan_uploader.name.store_path)

    settings = PlanUploaderSetting.select('column_name, column_num, is_pk').where("table_name = 'work_packages'").order('column_num ASC').all

    rows = []
    xlsx = Roo::Excelx.new(filename)
    xlsx.each_row_streaming(offset: @first_row_num.to_i - 1) do |row|
      rr = {}
      settings.each { |setting| rr[setting.column_name] = Hash['column_name', setting.column_name, setting.column_name, row[setting.column_num].value, 'is_pk', setting.is_pk] }

      rows.push rr
    end

    @project_for_load = Project.find(params[:project_id])

    rows.each do |row|
      if row.present?
        params = {}
        row.to_h.each do |r|
          params[r[0]] = r[1][r[0]]
        end

        is_new_record = false
        task = WorkPackage.where(:plan_num_pp => params['plan_num_pp'], :subject => params['subject'].to_s[0..250]).first_or_create! do |wp|
          is_new_record = true
          wp.subject = params['subject'].to_s[0..250]
          wp.due_date = params['due_date']
          wp.plan_num_pp = params['plan_num_pp']
          wp.description = params['description']

          if params['assigned_to_id'] == 0
            wp.assigned_to_id = nil
          end

          if (params['assigned_to_id'].present?)&&(params['assigned_to_id'] != 0)
            fio = params['assigned_to_id'].split(' ')
            user = User.find_or_create_by(firstname: fio[1], lastname: fio[0], patronymic: fio[2]) do |u|
              u.login = fio[0] + fio[1][0] + fio[2][0]
              u.login = Translit.convert(u.login.downcase, :english)
              u.admin = 0
              u.status = 1
              u.language = Setting.default_language
              u.type = User
              u.mail_notification = Setting.default_notification_option
              if Setting.mail_from.index("@") != nil
                u.mail = u.login + Setting.mail_from.to_s[Setting.mail_from.index("@")..Setting.mail_from.size-1]
              else
                u.mail = u.login + '@example.net'
              end
              u.first_login = true
            end
            wp.assigned_to_id = user.id

            #добавить юзера в участника проекта
            #project_members_path(project_id: @project_for_load, action: 'create')
            if Member.where(user_id: user.id, project_id: @project_for_load.id).count < 1
              @project_for_load.add_member!(user, Role.where(name: "Участник").first)
            end
          end

          if params['control_level_id'].present?
            # find control_level
          end

          if params['start_date'].present?
            if params['start_date'] == Date.parse('1899-12-30')
              wp.start_date = @project_for_load.created_on
            else
              wp.start_date  = Date.parse(params['start_date'].to_s)
            end
          end

          wp.project_id = @project_for_load.id
          wp.type_id = Type.find_by(name: I18n.t(:default_type_task)).id
          wp.status_id = Status.default.id # find_by(name: I18n.t(:default_status_new))
          wp.plan_type = 'execution'
          wp.author_id = User.current.id
          wp.position = 1
          wp.priority_id = IssuePriority.default.id
        end

        # тут надо обновление записи с занесением в журнал
        if !is_new_record

          if params['assigned_to_id'] == 0
            params['assigned_to_id'] = nil
          end

          if (params['assigned_to_id'].present?)&&(params['assigned_to_id'] != 0)
            fio = params['assigned_to_id'].split(' ')
            user = User.find_or_create_by(firstname: fio[1], lastname: fio[0], patronymic: fio[2]) do |u|
              u.login = fio[0] + fio[1][0] + fio[2][0]
              u.login = Translit.convert(u.login.downcase, :english)
              u.admin = 0
              u.status = 1
              u.language = Setting.default_language
              u.type = User
              u.mail_notification = Setting.default_notification_option
              if Setting.mail_from.index("@") != nil
                u.mail = u.login + Setting.mail_from.to_s[Setting.mail_from.index("@")..Setting.mail_from.size-1]
              else
                u.mail = u.login + '@example.net'
              end
              u.first_login = true
            end
            params['assigned_to_id'] = user.id

            #добавить юзера в участника проекта
            #project_members_path(project_id: @project_for_load, action: 'create')
            if Member.where(user_id: user.id, project_id: @project_for_load.id).count < 1
              @project_for_load.add_member!(user, Role.where(name: "Участник").first)
            end

          end

          if params['control_level_id'].present?
            # find control_level
          end

          if params['start_date'].present?
            if params['start_date'] == Date.parse('1899-12-30')
              params['start_date'] = @project_for_load.created_on
            else
              params['start_date'] = Date.parse(params['start_date'].to_s)
            end
          end

          params['project_id'] = @project_for_load.id
          params['type_id'] = Type.find_by(name: I18n.t(:default_type_task)).id
          params['status_id'] = Status.default.id # find_by(name: I18n.t(:default_status_new))
          params['plan_type'] = 'execution'
          params['author_id'] = User.current.id
          params['position'] = 1
          params['priority_id'] = IssuePriority.default.id

          WorkPackage.update(task.id, params)
        end

        # ищем id родителя
        plan_num_pp = params['plan_num_pp'].to_s
        if !plan_num_pp.rindex(".").nil?
          plan_num_pp = plan_num_pp[0..plan_num_pp.rindex(".")]
          plan_num_pp = plan_num_pp[0..plan_num_pp.size-2]
          parent_id = WorkPackage.where(project_id: @project_for_load.id, plan_num_pp: plan_num_pp).first.id

          # добавляем связи иерархии
          if parent_id.present?
            Relation.find_or_create_by(from_id: parent_id, to_id: task.id) do |rel|
              rel.from_id = parent_id
              rel.to_id = task.id
              rel.hierarchy = 1
            end
          end
        end
      end
    end
  end


  def prepare_roo
    Roo::Excelx::Cell::Number.module_eval do
      def create_numeric(number)
        return number if Roo::Excelx::ERROR_VALUES.include?(number)

        case @format
        when /%/
          Float(number)
        when /\.0/
          Float(number)
        else
          number.include?('.') || (/\A[-+]?\d+E[-+]?\d+\z/i =~ number) ? Float(number) : number.to_s.to_i
        end
      end
    end
  end


  def is_empty?
      #(@serial_number == nil || @serial_number == 0 || @serial_number == '') && (@name == nil || @name == 0 || @name == '')
  end


  private

  def russian_to_english_date(date_string)
    date_string.downcase.gsub(/январь|февраль|март|апрель|май|июнь|июль|август|сентябрь|октябрь|ноябрь|декабрь/, RUSSIAN_MONTH_NAMES_SUBSTITUTION)
  end

  def new_member(user_id)
    Member.new(permitted_params.member).tap do |member|
      member.user_id = user_id if user_id
    end
  end

end
