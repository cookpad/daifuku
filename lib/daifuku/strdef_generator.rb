module Daifuku
    # This class is used to generate .strdef file from .md files.
    # .strdef file is used to define the structure of the log.
    # https://techlife.cookpad.com/entry/2019/10/18/090000
    # Since the `.strdef` generation for Redshift Spectrum is for Cookpad's internal reasons,
    # we initially decided it would be more natural not to include it in the core of daifuku,
    # but we added it as a reference implementation.
    class StrdefGenerator
      class StreamDefinition
        def self.parse(strdef)
          columns = {}
          strdef.each_line do |line|
            case line
            when /\A\s*-\s+(\w+):\s*(!domain\s+\w+|!\w+)(?:\s+(\d+))?/
              name = $1
              type = $2.sub(/\s+/, ' ').sub(/\A!/, '')
              length = $3
              columns[name] = StreamColumn.new(name, type, length&.to_i)
            end
          end
          new(columns)
        end
  
        include Enumerable
  
        def initialize(columns)
          @columns = columns
        end
  
        def each_column(&block)
          @columns.each_value(&block)
        end
  
        def [](name)
          @columns[name]
        end
      end
  
      class StreamColumn
        def initialize(name, type, length = nil)
          @name = name
          @type = type
          @length = length
        end
  
        attr_reader :name
        attr_reader :type
        attr_reader :length
  
        def strdef
          if length
            "#{name}: !#{type} #{length}"
          else
            "#{name}: !#{type}"
          end
        end
      end
  
      class LogTable
        PREDEFINED = %w[id log_id event_category event_name]
  
        def self.predefined_column?(name)
          PREDEFINED.include?(name)
        end
  
        def initialize
          @columns = {}
        end
  
        def add_common_column(column)
          @columns[column.name] = LogColumn.new(column.name, column.type, true)
        end
  
        def add_column(column, location = '-')
          if prev = @columns[column.name]
            if prev.common?
              raise "common column is being overwritten: #{column.name}: location=#{location}"
            end
            unless column.type.name == prev.type.name
              raise "column type mismatch: name=#{column.name}, curr=#{column.type.name}, prev=#{prev.type.name}"
            end
          end
          @columns[column.name] = LogColumn.new(column.name, column.type)
        end
  
        def [](name)
          @columns[name]
        end
  
        def each_column(&block)
          @columns.each_value(&block)
        end
      end
  
      class LogColumn
        def initialize(name, type, is_common = false)
          @name = name
          @type = type
          @is_common = is_common
        end
  
        attr_reader :name
        attr_reader :type
  
        def common?
          @is_common
        end
  
        def strdef
          if type.str_length
            "#{name}: !#{type.name} #{type.str_length}"
          else
            "#{name}: !#{type.name}"
          end
        end
      end
  
      # @param definition_path A directory path it contains log definitions
      def initialize(definition_path)
        @definition_path = definition_path
      end
  
      # Generate whole strdef from current log definitions
      # @return String
      def generate
        table = load_table_definition(@definition_path)
        generate_strdef(table)
      end
  
      # Generate strdef diff with existing strdef
      # @param String current_strdef strdef to diff with
      # @return String diff
      def diff(current_strdef)
        table = load_table_definition(@definition_path)
        generate_strdef_diff(current_strdef, table)
      end
  
      private
      def load_table_definition(path_prefix)
        table = LogTable.new
  
        categories = Daifuku::Compiler.new.compile(path_prefix)
  
        if common = categories.delete('common')
          common.common_columns.each do |column|
            table.add_common_column(column)
          end
        end
  
        categories.each do |category_name, category|
          category.common_columns.each do |column|
            table.add_column column, "#{category_name}:common"
          end
          category.events.each do |event_name, event|
            event.columns.each do |column|
              table.add_column column, category_name
            end
          end
        end
  
        table
      end
  
      def generate_strdef(table)
        lines = ["columns:"]
        table.each_column do |column|
          lines << "  - #{column.strdef}"
        end
        lines.join("\n") + "\n"
      end
  
      def generate_strdef_diff(strdef, table)
        strdef = StreamDefinition.parse(strdef)
  
        lines = []
        found = false
        table.each_column do |column|
          unless strdef[column.name]
            lines << "- #{column.strdef}"
            found = true
          end
        end
  
        unless found
          $stderr.puts %Q(INFO: no new column added)
        end
  
        strdef.each_column do |column|
          if not table[column.name] and not LogTable.predefined_column?(column.name)
            $stderr.puts %Q(INFO: column "#{column.name}" is no longer generated)
          end
        end
        lines.join("\n") + "\n"
      end
    end
  end
