require '../lib/sql_class.rb'

class Farmer < SQLClass
  has_many :coops
  has_many_through :chickens, :coops, :chickens
  validates :name, presence: true, uniqueness: true

  finalize!
end

class Coop < SQLClass
  belongs_to :farmer
  has_many :chickens
  validates :location, :farmer_id, presence: true

  finalize!
end

class Chicken < SQLClass
  belongs_to :coop
  has_one_through :farmer, :coop, :farmer
  validates :name, :coop_id, presence: true

  finalize!
end
