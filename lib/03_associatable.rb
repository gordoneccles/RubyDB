require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

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
  # Phase IIIb
  def belongs_to(owner, options = {})
    owner_info = BelongsToOptions.new(owner, options)

    assoc_options[owner] = owner_info

    define_method(owner.to_s) do
      results = DBConnection.execute(<<-SQL)
        SELECT
          *
        FROM
          #{owner_info.table_name}
        WHERE
          #{owner_info.table_name}.#{owner_info.primary_key} = #{self.send(:id)}
      SQL

      owner_info.model_class.parse_all(results).last
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

  def assoc_options
    @assoc_options ||= Hash.new
  end
end

class SQLObject
  extend Associatable
end
