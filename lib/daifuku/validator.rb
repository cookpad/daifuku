module Daifuku
  class Violation
    attr_reader :message

    def initialize(message, category_name:, event_name:, column_name:)
      @message = message
      @category_name = category_name
      @event_name = event_name
      @column_name = column_name
    end
  end


  class Rule
    def validate!(categories)
      raise "Not implemented"
    end
  end

  class MultipleTypesRule < Rule
    def validate!(categories)
      violations = []
      all_columns = categories.values.map { |category| category.events.values.map { |event| event.columns }}.flatten
      columns_by_name = all_columns.group_by { |column| column.name }
      all_duplicated_columns = columns_by_name.filter { |_, columns| columns.size >= 2 }
      all_duplicated_columns.each do |name, columns|
        unless columns.map { |column| column.type }.uniq { |type| [type.name, type.str_length] }.size == 1
          violations << Violation.new("Multiple types are found for '#{name}'",
                                      category_name: nil,
                                      event_name: nil,
                                      column_name: name)
        end
      end
      violations
    end
  end

  class ShadowingRule < Rule
    def validate!(categories)
      violations = []
      common_category = categories[COMMON_CATEGORY_NAME]
      return [] unless common_category&.common_columns
      all_common_columns = common_category.common_columns.map(&:name)
      categories.each_value do |category|
        next if category.name == COMMON_CATEGORY_NAME
        category.events.each_value do |event|
          event.columns.each do |column|
            if all_common_columns.include?(column.name)
              message = "Column '#{column.name}' on '#{category.name}' is already defined on common columns"
              violations << Violation.new(message, category_name: category.name, event_name: event.name, column_name: column.name)
            end
          end
        end
      end
      violations
    end
  end

  class ReservedColumnsRule < Rule
    RESERVED_COLUMNS = %w(event_name event_category log_id id)

    def validate!(categories)
      violations = []
      categories.each_value do |category|
        category.events.each_value do |event|
          event.columns.each do |column|
            message = "'#{column.name}' is reserved"
            violations << Violation.new(message, category_name: category.name, event_name: event.name, column_name: column.name)  if RESERVED_COLUMNS.include?(column.name)
          end
        end
      end
      violations
    end
  end

  class NameLengthRule < Rule
    attr_reader :max_length

    def initialize(max_length)
      @max_length = max_length
    end

    def validate!(categories)
      violations = []
      categories.each_value do |category|
        if category.name.length > max_length
          violations << Violation.new("#{category.name} must be within #{max_length} characters.",
                                      category_name: category.name,
                                      event_name: nil,
                                      column_name: nil)
        end
        category.events.each_value do |event|
          if event.name.length > max_length
            violations << Violation.new("#{category.name}.#{event.name} must be within #{max_length} characters.",
                                        category_name: category.name,
                                        event_name: event.name,
                                        column_name: nil)
          end
          event.columns.each do |column|
            if column.name.length > max_length
              violations << Violation.new("#{category.name}.#{event.name}.#{column.name} must be within #{max_length} characters.",
                                          category_name: category.name,
                                          event_name: event.name,
                                          column_name: column.name)
            end
          end
        end
      end
      violations
    end
  end

  class Validator
    def initialize(rules)
      @rules = rules
    end

    def validate!(categories)
      violations = []
      @rules.each do |rule|
        violations += rule.validate!(categories)
      end
      violations.flatten!
      raise violations.map(&:message).join("\n") unless violations.empty?
    end
  end
end
