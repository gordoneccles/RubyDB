# RubyDB
RubyDB makes accessing and manipulating information in a SQL database easy and intuitive.

## Setup
First ensure your sqlite3 database is located in the root directory. This allows the database wrapper to find it.

To implement RubyDB create a new class to represent your SQL table. Have this class inherit from `SQLClass`, and at the end of your new class's definition, call the `::finalize!` method to ensure attribute setter and getter methods are created.

That's it! You can now interact with your table via the new Ruby class.

## Class Table Name and Column Names
A SQLCLass subclass will infer its table based off its classname, and it's therefore important to correctly CamelCase and singularize it. However if for whatever reason the inferred table name is incorrect, it can be set manually using the `::table_name=` method.

Once the table name is correctly setup, a SQLClass subclass will query the database for its column names. Instances of this class will have instance variables for the corresponding column names that can be read and updated.

## Validations
Instances of a SQLClass subclass can be configured to validate their attributes before committing to the database. In order to set this up, include a `validates` method in the class definition. This method takes a list of attribute symbols as arguments, as well as a params hash of what validations should be run. For example: `validates :owner_id, presence: true`.

## Querying the Database
Use the `::find(id)` method to search the database for a single instance of this class based off it's primary key. This method returns an instance of the same class that was used for the search, not SQL data or a hash.

Use the `::all()` method to return all instances of a particular class or the `::where(params)` method to filter based off the params hash.

## Creating and Updating Data
Instances of a SQLClass subclass have instance variables to store all associated database information. These attributes can be viewed together via the `#attributes` methods, and read/updated like regular ruby instance variables.

To persist an instance to the database, called the `#save` method, which will update the instance's fields or else create a new row if the instance does not yet exist in the database.

## Associations
RubyDB allows for associations between tables that make querying for one-to-many and many-to-one relationships as simple as a single method call. In order to setup associations, include the `::has_many` or `::belongs_to` methods as appropriate in the class definition. Be sure to pass in an argument of the target in the relationship. Targets should be snake_case symbols, and plural or singular as appropriate. RubyDB will infer the table name, class name, and foreign key from this argument, but these attributes can be overridden by supplying them in an options hash. E.g. `has_many :chicks, class_name: 'Chicken', foreign_key: 'farmer_id'`.

RubyDB associations can also be setup for one-to-one-through and one-to-many-through relationships. In this case use the `::has_one_through` method, passing in arguments for all `(:target_name, :relay_name, :name_of_target_on_relay)`. The relay name should match the association on the primary class. The name of the target on the relay should match the name of the target association on the relay. Both these associations must be setup for the one-to-one-through association to function.

## Example Setup
```ruby
class Farmer < SQLClass
  has_many :coops
  has_many_through :chickens, :coops, :chickens
  validates :name, presence: true, uniqueness: true

  finalize!
end

class Coop < SQLClass
  belongs_to :farmer
  has_many :chickens
  validates :location, :farmer_id, presence: true

  finalize!
end

class Chicken < SQLClass
  belongs_to :coop
  has_one_through :farmer, :coop, :farmer
  validates :name, :coop_id, presence: true

  finalize!
end
```
