module Daifuku
  DEFAULT_NAME_LENGTH = 64

  class Compiler
    attr_reader :options

    # Compile markdowns into Ruby objects.
    # @param directory_path String Directory path containing log definitions.
    # @param options [String: Object] Compiler options
    # @return [String: Category]
    def compile(directory_path, options = {})
      @options = options
      categories = Dir.entries(directory_path).map do |file|
        if file.end_with?('.md')
          category_name = File.basename(file, '.md')
          path = File.join(directory_path, file)
          # This situation implicates missing LANG, use UTF-8 by default.
          enc = (Encoding.default_external == Encoding::US_ASCII) ? Encoding::UTF_8 : Encoding.default_external
          str = File.read(path, encoding: enc)
          parser.parse(str, category_name)
        end
      end.compact.map { |category| [category.name, category] }.to_h
      validator.validate!(categories)
      categories
    end

    def parser
      @parser ||= Parser.new
    end

    private
    def validator
      @validator ||= Validator.new([MultipleTypesRule.new,
                                    ReservedColumnsRule.new,
                                    ShadowingRule.new,
                                    NameLengthRule.new(name_length)])
    end

    def name_length
      options[:name_length] || DEFAULT_NAME_LENGTH
    end
  end
end
