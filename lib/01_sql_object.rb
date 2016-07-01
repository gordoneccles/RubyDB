require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.
require 'byebug'

class SQLObject
  def self.columns
    return @columns unless @columns.nil?

    results = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    @columns = results.first.map{ |name| name.to_sym}
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

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.downcase + "s"
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

  def self.col_names
    "(" + self.columns.map{ |col| col.to_s }.join(", ") + ")"
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

  def save
    attributes[:id].nil? ? insert : update
  end

end
