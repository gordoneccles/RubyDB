require_relative 'db_connection'
require 'byebug'

module Validatable

  def self.validates(*attribute_names, options)
    @validations = [];

    options.each_key do |option|
      attribute_names.each do |attribute_name|
        @validations << Proc.new { raise "#{attribute_name} cannot be blank" )}
      end
    end
  end

  def self.make_validation(option, attribute_name)
    if option == :presence
      return Proc.new { raise "#{attribute_name} cannot be blank" )}
    elsif option == :uniqueness
      return Proc.new { raise "#{attribute_name} must be unique" unless self.send("unique?", attribute_name)}
    end
  end

  def validate!
    @validations.each do |validation|
      validation.call
    end
  end

  def unique?(attribute_name)
    value = self.send("#{attribute_name}")

    results = DBConnection.execute(<<-SQL, value)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{attribute_name} = ?
    SQL

    if results.length == 0 || (results.length == 1 && results.first.id == self.id)
      return true
    end

    false
  end

end
