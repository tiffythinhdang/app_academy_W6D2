require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @result ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        '#{self.table_name}'
    SQL
    @result.first.map!{ |col| col.to_sym }
  end

  def self.finalize!
    self.columns.each do |col|
      # instance_name = "@#{col}"
      setter_name = "#{col}="

      define_method(col) do
        # instance_variable_get(instance_name)
        self.attributes[col]
      end

      define_method(setter_name) do |new_val|
        # instance_variable_set(instance_name, new_val)
        self.attributes[col] = new_val
      end
 
    end
  end

  def self.table_name=(table_name)
  end

  def self.table_name
    self.to_s.downcase + "s"
  end

  def self.all
    all_objects = DBConnection.execute(<<-SQL)
      SELECT
        '#{self.table_name}'.*
      FROM
        '#{self.table_name}'
    SQL
    self.parse_all(all_objects)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    object = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL
    object.empty? ? nil : ( self.parse_all(object).first )
  end

  def initialize(params = {})
    params.each do |k, v|
      attr_name = k.to_sym
      raise "unknown attribute '#{k}'" unless self.class.columns.include?(attr_name)
      self.send("#{attr_name}=", v)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map{ |col| send(col) }
  end

  def insert
    col_length = self.class.columns.drop(1)
    col_val = col_length.map(&:to_s).join(", ")
    question_marks = (["?"] * (col_length.length) ).join(", ")
    # question_marks = question_marks.join(", ")
    
    DBConnection.execute(<<-SQL, *self.attribute_values.drop(1) )
      INSERT INTO
        '#{self.class.table_name}' (#{col_val})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_row = self.class.columns.map{ |col| "#{col} = ?" }.join(", ")
    DBConnection.execute(<<-SQL, *self.attribute_values, self.id)
      UPDATE
        '#{self.class.table_name}'
      SET
        #{set_row}
      WHERE
        id = ?
    SQL
  end

  def save
    self.id.nil? ? self.insert : self.update
  end
end
