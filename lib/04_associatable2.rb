require_relative '03_associatable'

# Phase IV
module Associatable

  def has_one_through(target_name, relay_name, relays_name_for_target)
    relay = self.assoc_options[relay_name]


    define_method(target_name) do
      target = relay.model_class.assoc_options[relays_name_for_target]

      results = DBConnection.execute(<<-SQL)
        SELECT
          #{target.table_name}.*
        FROM
          #{relay.table_name}
        JOIN
          #{target.table_name} ON
            #{relay.table_name}.#{target.foreign_key} =
            #{target.table_name}.#{target.primary_key}
        WHERE
          #{relay.table_name}.#{relay.primary_key} = #{self.send(relay.foreign_key)}
      SQL

      target.model_class.parse_all(results).last

    end

  end
end
