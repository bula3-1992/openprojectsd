class Stakeholder < ActiveRecord::Base

  belongs_to :target # целевой показатель, для которого приводится методика
  belongs_to :project

end