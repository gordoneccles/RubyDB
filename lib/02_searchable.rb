require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{att_equals_q(params)}
    SQL

    self.parse_all(results)
  end

  def att_equals_q(params)
    params.map { |key, value| "#{key} = ?" }.join(" AND ")
  end
end

class SQLObject
  extend Searchable
end
