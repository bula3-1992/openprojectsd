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

class Comment < ActiveRecord::Base
  belongs_to :commented, polymorphic: true, counter_cache: true
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'

  validates :commented, :author, :comments, presence: true

  after_create :send_news_comment_added_mail

  def text
    comments
  end

  def post!
    save!
  end

  private

  def send_news_comment_added_mail
    return unless Setting.is_notified_event('news_comment_added')
    #+-tan 2019.11.30
    recip = commented.recipients + commented.watcher_recipients
    if (Setting.is_strong_notified_event('news_comment_added'))
      recip = commented.all_recipients + commented.watcher_recipients
    end

    return unless commented.is_a?(News)

    #recipients = commented.recipients + commented.watcher_recipients
    recip.uniq.each do |user|
      if Setting.can_notified_event(user, 'news_comment_added')
        UserMailer.news_comment_added(user, self, User.current).deliver_later
      end
    end
  end
end
