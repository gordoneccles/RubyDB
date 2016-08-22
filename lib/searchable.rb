require_relative 'db_connection'

module Searchable
  def where(params)
    @relation = Relation.new(params, self)
  end
end

class Relation

  def initialize(params, sql_class)
    @params = params
    @class = sql_class
  end

  def where(params)
    params.each_key do |key|
      @params[key] = params[key]
    end
  end

  def first
    execute.first
  end

  def last
    execute.last
  end

  def [](idx)
    execute[idx]
  end

  def execute
    results = DBConnection.execute(<<-SQL, *@params.values)
      SELECT
        *
      FROM
        #{@class.table_name}
      WHERE
        #{att_equals_?}
    SQL

    @class.parse_all(results)
  end

  def inspect
    execute.inspect
  end

  private

  def att_equals_?
    @params.map { |key, value| "#{key} = ?" }.join(" AND ")
  end
end
