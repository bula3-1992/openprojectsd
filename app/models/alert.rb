class Alert < ActiveRecord::Base
  def self.create_new_pop_up_alert(entityid,entitytype,aboutwhat,createdby,touser)
    text = ""
    user_created=User.where(id: createdby).map {|u| [u.lastname, u.firstname, u.patronymic]}

    case aboutwhat
    when "Due"
      text += "Истекает срок исполнения мероприятия "
    when "Created"
      text += "Создана новая запись в таблице "
    when "Changed"
      text += "Была изменена запись в таблице "
    when "Moved"
      text += "Запись была перенесена в другую таблицу "
    when "Deleted"
      text += "Была удалена запись из таблицы "
    end

    case entitytype
    when "Boards"
      text += "Дискусии"
    when "WorkPackages"
      text += "Мероприятия"
    when "News"
      text += "Новости"
    when "Projects"
      text += "Проекты"
    when "Members"
      text += "Участники"
    end

    if createdby.zero?
      text += ". Cоздано системой в"
    else
      text += ". Cоздано " + user_created[0][0] + " "
      if user_created[0][1]!= nil
        text += user_created[0][1].slice(0...1) + ". "
      end
      if user_created[0][2]!= nil
        text += user_created[0][2].slice(0...1) + ". "
      end
      text += "в "
    end
    text += Time.current.to_formatted_s(:time)
    Alert.create entity_id: entityid,
                 alert_date: Date.today,
                 entity_type: entitytype,
                 alert_type: "PopUp",
                 about: text,
                 created_by: createdby,
                 to_user: touser
  end

  def self.create_pop_up_alert(entity, aboutwhat,createdby,touser)
    text = ""
    fio = createdby.name(:lastname_f_p)
    class_name = entity.class.to_s
    #Истекающий срок
    if aboutwhat == "Due" && class_name =="WorkPackage"
      text += "Срок исполнения мероприятия #{entity.subject} истекает #{entity.due_date}"
      #Создание
    elsif aboutwhat == "Created" && class_name == "WorkPackage"
      text += "Пользователь #{fio} назначил вам мероприятие #{entity.subject}"

    elsif aboutwhat == "Created" && class_name == "Member"
      text += "Пользователь #{fio} добавил вас в проект #{entity.project.name}"

    elsif aboutwhat == "Created" && class_name == "Board"
      text += "Пользователь #{fio} создал дискуссию #{entity.name}"

    elsif aboutwhat == "Created" && class_name == "Project"
      text += "Пользователь #{fio} создал проект #{entity.name}"

    elsif aboutwhat == "Changed" && class_name == "News"
      text += "Пользователь #{fio} написал новость о #{entity.title}"
      #Изменение
    elsif aboutwhat == "Changed" && class_name == "WorkPackage"
      text += "Пользователь #{fio} изменил ваше мероприятие #{entity.subject}"

    elsif aboutwhat == "Changed" && class_name == "Member"
      text += "Пользователь #{fio} изменил ваш статус в проекте #{entity.project.name}"

    elsif aboutwhat == "Changed" && class_name == "Board"
      text += "Пользователь #{fio} изменил дискуссию #{entity.name}"

    elsif aboutwhat == "Changed" && class_name == "Project"
      text += "Пользователь #{fio} изменил проект #{entity.name}"

    elsif aboutwhat == "Changed" && class_name == "News"
      text += "Пользователь #{fio} изменил новость о #{entity.title}"
      #Удаление
    elsif aboutwhat == "Deleted" && class_name == "WorkPackage"
      text += "Пользователь #{fio} удалил ваше мероприятие #{entity.subject}"

    elsif aboutwhat == "Deleted" && class_name == "Member"
      text += "Пользователь #{fio} исключил вас из проекта #{entity.project.name}"

    elsif aboutwhat == "Deleted" && class_name == "Board"
      text += "Пользователь #{fio} удалил дискуссию #{entity.name}"

    elsif aboutwhat == "Deleted" && class_name == "Project"
      text += "Пользователь #{fio} удалил проект #{entity.name}"

    elsif aboutwhat == "Deleted" && class_name == "News"
      text += "Пользователь #{fio} стер новость о #{entity.title}"
      #Перенесение

    elsif aboutwhat == "Moved" && class_name == "Board"
      text += "Пользователь #{fio} переместил дискуссию #{entity.name}"
      #Текст уведомления по умолчанию
    else
      text += default_pop_up_alert_text(entity, aboutwhat, createdby, touser)

    end
    text += "^в "
    text += Time.current.to_formatted_s(:time)
      Alert.create entity_id: entity.id,
                 alert_date: Date.today,
                 entity_type: class_name,
                 alert_type: "PopUp",
                 about: text,
                 created_by: createdby.id,
                 to_user: touser.id
  end

  private
  def self.default_pop_up_alert_text(entity, aboutwhat,createdby,touser)
    text = ""
    fio = createdby.name(:lastname_f_p)
    klass_name = entity.class.to_s
    case aboutwhat
    when "Due"
    text += "Истекает срок исполнения мероприятия "
    when "Created"
    text += "Создано "
    when "Changed"
    text += "Изменено"
    when "Moved"
    text += "Перенесено"
    when "Deleted"
    text += "Удалено"
    end

    case klass_name
    when "Board"
    text += "Дискусии"
    when "WorkPackage"
    text += "Мероприятия"
    when "New"
    text += "Новости"
    when "Project"
    text += "Проекты"
    when "Member"
    text += "Участники"
    end

    if createdby == nil
      text += ". Cоздано системой в"
      else
      text += ". Cоздано " + fio + " "
      text += "в "
      end
    text += Time.current.to_formatted_s(:time)
    text
  end
end
