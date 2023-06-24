module Daifuku
  class Category
    # @return String
    attr_reader :name
    # @return [String: Event]
    attr_reader :events
    # @return String
    attr_reader :descriptions
    # @return [Column]
    attr_reader :common_columns

    def initialize(name, events, descriptions, common_columns)
      @name = name
      @events = events
      @descriptions = descriptions
      @common_columns = common_columns
    end

    def dump
      {
        'name' => name,
        'events' => events.to_h { |name, event| [name, event.dump] },
        'descriptions' => descriptions,
        'common_columns' => common_columns.map(&:dump),
      }
    end
  end

  class Event
    # @return String
    attr_reader :name
    # @return [Column]
    attr_reader :columns
    # @return String
    attr_reader :descriptions

    def obsolete?
      @is_obsolete
    end

    def initialize(name, columns, descriptions, is_obsolete)
      @name = name
      @columns = columns
      @descriptions = descriptions
      @is_obsolete = is_obsolete
    end

    def dump
      {
        'name' => name,
        'columns' => columns.map(&:dump),
        'descriptions' => descriptions,
        'is_obsolete' => obsolete?,
      }
    end
  end

  class Column
    # @return String
    attr_reader :name
    # @return Type
    attr_reader :type
    # @return [String]
    attr_reader :descriptions

    def obsolete?
      @is_obsolete
    end

    def initialize(name, type, descriptions, is_obsolete = false)
      @name = name
      @type = type
      @descriptions = descriptions
      @is_obsolete = is_obsolete
    end

    def self.parse(descriptor, descriptions)
      # column_name: !bigint
      # column_name: !bigint?
      # column_name: !string 256
      # column_name: !string? 256
      # column_name: CustomType
      # [obsolete] column_type: !bigint
      if descriptor =~ /(\[obsolete\])?\s*(\w+):\s*(!?\w+\??(?:\s(\d+))?)/
        obsolete = $1 != nil
        name = $2
        type = Type.parse($3)
        Column.new(name, type, descriptions, obsolete)
      else
        raise "Could not parse column '#{descriptor}'"
      end
    end

    def strdef
      if type.name == 'string' && type.str_length
        "#{name}: !#{type.name} #{type.str_length}"
      elsif !type.custom?
        "#{name}: !#{type.name}"
      else
        "#{name}: #{type.name}"
      end
    end

    def dump
      {'name' => name, 'type' => type.dump, 'descriptions' => descriptions}
    end
  end

  class Type
    AVAILABLE_BUILTIN_TYPES = %w(
      smallint
      integer
      bigint
      real
      double
      boolean
      string
      date
      timestamp
      timestamptz
    )
    # @return String
    attr_reader :name
    # Length for built-in String types
    # This parameter returns nil when type is not String
    # @return Integer?
    attr_reader :str_length

    def initialize(name, optional, custom, str_length = nil)
      @name = name
      @is_optional = optional
      @is_custom = custom
      @str_length = str_length
      unless custom
        raise "Invalid built-in type #{name}" unless AVAILABLE_BUILTIN_TYPES.include?(name)
      end
    end

    # @return Boolean
    def optional?
      @is_optional
    end

    # Boolean value which indicates whether this type is user defined types or not.
    # @return Boolean
    def custom?
      @is_custom
    end

    def self.parse(descriptor)
      type_name, str_length = descriptor.split
      is_optional = type_name.end_with?('?')
      type_without_optional = type_name.gsub(/\?$/, '')
      custom = !type_name.start_with?('!')
      if custom
        raise "Doesn't support str_length for custom types #{type_name}" unless str_length.nil?
        Type.new(type_without_optional, is_optional, custom, nil)
      else
        built_in_type_name = type_without_optional.gsub(/^!/, '')
        raise "type_name '#{built_in_type_name}' is not allowed" unless AVAILABLE_BUILTIN_TYPES.include?(built_in_type_name)
        raise "length for '#{built_in_type_name}' is not supported" if built_in_type_name != 'string' && !str_length.nil?

        Type.new(built_in_type_name, is_optional, custom, str_length&.to_i)
      end
    end

    def dump
      {'name' => name, 'optional' => optional?, 'is_custom' => custom?, 'str_length' => str_length}
    end
  end
end
