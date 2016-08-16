require 'active_support/inflector'

class AssocOptions
  attr_accessor :primary_key, :foreign_key, :class_name

  def model_class
    @class_name.constantize
  end

  def table_name
    @class_name.underscore + "s"
  end
end

class BelongsToOptions < AssocOptions

  def initialize(owner, options = {})

    @primary_key = options[:primary_key] || :id
    @foreign_key = options[:foreign_key] || (owner.to_s.downcase.singularize.underscore + "_id").to_sym
    @class_name = options[:class_name] || owner.to_s.singularize.camelcase
    @table_name = options[:table_name] || owner.to_s.pluralize.camelcase

  end
end

class HasManyOptions < AssocOptions
  def initialize(ownees, my_class_name, options = {})

    @class_name = options[:class_name] || ownees.to_s.singularize.camelcase
    @primary_key = options[:primary_key] || :id
    @foreign_key = options[:foreign_key] || (my_class_name.to_s.downcase.singularize.underscore + "_id").to_sym
    @table_name = options[:table_name] || ownees.to_s.pluralize.camelcase

  end
end

module Associatable
  def belongs_to(owner, options = {})
    owner_db_attributes = BelongsToOptions.new(owner, options)

    assoc_options[owner] = owner_db_attributes

    define_method(owner.to_s) do
      results = DBConnection.execute(<<-SQL)
        SELECT
          *
        FROM
          #{owner_db_attributes.table_name}
        WHERE
          #{owner_db_attributes.table_name}.#{owner_db_attributes.primary_key} = #{self.send(:id)}
      SQL

      owner_db_attributes.model_class.parse_all(results).last
    end
  end

  def has_many(ownees, options = {})
    ownee_info = HasManyOptions.new(ownees, self.to_s, options)

    define_method(ownees.to_s) do
      results = DBConnection.execute(<<-SQL)
        SELECT
          *
        FROM
          #{ownee_info.table_name}
        WHERE
          #{ownee_info.table_name}.#{ownee_info.foreign_key} = #{self.send(:id)}
      SQL

      ownee_info.model_class.parse_all(results)
    end
  end

  def has_one_through(target_name, relay_name, relays_name_for_target)
    relay_db_attributes = self.assoc_options[relay_name]


    define_method(target_name) do
      target_db_attributes = relay_db_attributes.model_class.assoc_options[relays_name_for_target]

      results = DBConnection.execute(<<-SQL)
        SELECT
          #{target_db_attributes.table_name}.*
        FROM
          #{relay_db_attributes.table_name}
        JOIN
          #{target_db_attributes.table_name} ON
            #{relay_db_attributes.table_name}.#{target_db_attributes.foreign_key} =
            #{target_db_attributes.table_name}.#{target_db_attributes.primary_key}
        WHERE
          #{relay_db_attributes.table_name}.#{relay_db_attributes.primary_key} = #{self.send(relay_db_attributes.foreign_key)}
      SQL

      target_db_attributes.model_class.parse_all(results).last

    end
  end

  def assoc_options
    @assoc_options ||= Hash.new
  end
end
