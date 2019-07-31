class Raion < ActiveRecord::Base
  self.inheritance_column = nil # иначе колонка type используется для
  # single table inheritance т.е наследования сущностей, хранящихся в одной таблице
  has_many :work_packages, foreign_key: 'raion_id', dependent: :nullify

  def to_s
    name
  end
end