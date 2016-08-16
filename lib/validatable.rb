require_relative 'db_connection'

module Validatable

  def self.included(base)
    base.extend ClassValidations
  end

  module ClassValidations
    def validates(*attribute_names, options)
      @validations = [];

      options.each_key do |option|
        attribute_names.each do |attribute_name|
          @validations << make_validation(option, attribute_name)
        end
      end

    end

    def make_validation(option, attribute_name)
      if option == :presence
        return "raise \"#{attribute_name} cannot be blank\" unless send(\"#{attribute_name}\")"
      elsif option == :uniqueness
        return "raise \"#{attribute_name} must be unique\" unless send(\"unique?\", \"#{attribute_name}\")"
      end
    end

    def validations
      @validations
    end
  end


  def validate!
    self.class.validations.each do |validation|
      self.instance_eval(validation)
    end
  end

  def unique?(attribute_name)
    value = self.send("#{attribute_name}")

    results = DBConnection.execute(<<-SQL, value)
      SELECT
        *
      FROM
        #{self.class.table_name}
      WHERE
        #{attribute_name} = ?
    SQL

    if results.length == 0 || (results.length == 1 && results.first["id"] == self.id)
      return true
    end

    false
  end

end
