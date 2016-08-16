require_relative 'db_connection'

module Searchable
  def where(params)
    
    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{att_equals_?(params)}
    SQL

    self.parse_all(results)
  end

  private

  def att_equals_?(params)
    params.map { |key, value| "#{key} = ?" }.join(" AND ")
  end
end

class Relation

    def initialize(source_class_name)
      @source_class = source_class_name.constantize
    end

end
