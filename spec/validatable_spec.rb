require 'sql_class'
require 'db_connection'
require 'securerandom'

describe SQLClass do
  before(:each) { DBConnection.reset }
  after(:each) { DBConnection.reset }

  before(:all) do
    class Cat < SQLClass
      validates :name, presence: true
      finalize!
    end
  end

  describe "::validates" do

    it "raises an error upon saving" do
      c = Cat.new(name: nil)
      expect(c.save).to raise_error
    end

    it "doesn't raise an error when validations are satisfied" do
      c = Cat.new(name: "Kit")
      expect(c.save).to_not raise_error
    end
  end
end
