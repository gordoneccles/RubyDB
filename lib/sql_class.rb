require_relative 'db_connection'
require_relative 'searchable'
require_relative 'associatable'
# require_relative 'validatable'
require 'byebug'

class SQLObject
  extend Searchable
  extend Associatable
  # include Validatable

  def self.validates(*attribute_names, options)
    @@validations = [];
    options.each_key do |option|
      attribute_names.each do |attribute_name|
        @@validations << make_validation(option, attribute_name)
      end
    end
  end

  def make_validation(option, attribute_name)
    if option == :presence
      return Proc.new { raise "#{attribute_name} cannot be blank" unless send("#{attribute_name}") }
    elsif option == :uniqueness
      return Proc.new { raise "#{attribute_name} must be unique" unless self.send("unique?", attribute_name)}
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.get_table_name
  end

  def self.get_table_name
    table_name = ""

    self.to_s.each_char.with_index do |char, idx|
      if idx == 0
        table_name << "#{(char.ord + 32).chr}"
      elsif char.ord >= 65 && char.ord <=90
        table_name << "_#{(char.ord + 32).chr}"
      else
        table_name << char
      end
    end

    table_name << "s"
  end

  def self.columns
    @columns ||= self.get_columns
  end

  def self.get_columns
    results = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    results.first.map{ |name| name.to_sym}
  end

  def self.col_names
    "(" + self.columns.map{ |col| col.to_s }.join(", ") + ")"
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column.to_s) do
        attributes[column]
      end

      define_method(column.to_s + "=") do |val|
        attributes[column] = val
      end
    end
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map { |object| self.new(object) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    return if results.empty?

    self.new(results.first)
  end

  def initialize(params = {})
    params.each do |key, value|
      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key.to_sym)
      send("#{key}=", value)
    end
  end

  def attributes
    @attributes ||= Hash.new
  end

  def insert
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} #{self.class.col_names}
      VALUES
        #{question_marks}
    SQL

    id = DBConnection.last_insert_row_id
    attributes[:id] = id
  end

  def question_marks
    marks = []
    self.class.columns.length.times { marks << "?" }
    "(" + marks.join(", ") + ")"
  end

  def attribute_values
    self.class.columns.map{ |att| attributes[att] }
  end

  def column_equals
    self.class.columns.map{ |column| column.to_s }.join(" = ?, ") + " = ?"
  end

  def update
    DBConnection.execute(<<-SQL, *attribute_values, attributes[:id])
      UPDATE
        #{self.class.table_name}
      SET
        #{column_equals}
      WHERE
        id = ?
    SQL
  end

  def validate!
    @@validations.each do |validation|
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

  def save
    validate!
    attributes[:id].nil? ? insert : update
  end

end
