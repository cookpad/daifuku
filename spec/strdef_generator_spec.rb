require 'spec_helper'
include Daifuku

FIXTURE_PATH = File.absolute_path(File.join(__dir__, 'fixtures'))

RSpec.describe StrdefGenerator do
  let(:definition_path) { File.join(FIXTURE_PATH, 'sample') }
  let(:generator) { StrdefGenerator.new(definition_path) }

  describe '#generate' do
    it 'will generate correct strdef' do
      expects = <<STRDEF
columns:
  - common_column0: !integer
  - column0: !integer
  - column1: !string
  - column2: !integer
  - column_with_str_length: !string 1024
  - column_with_custom_type: !MyClass
  - column3: !integer
STRDEF
      expect(generator.generate).to eql expects
    end
  end

  describe '#diff' do
    it 'will generate correct strdef diff' do
      current = <<STRDEF
columns:
  - common_column0: !integer
  - column0: !integer
  - column2: !integer
  - column3: !integer
STRDEF
      expects = <<DIFF
- column1: !string
- column_with_str_length: !string 1024
- column_with_custom_type: !MyClass
DIFF
      expect(generator.diff(current)).to eql expects
    end
  end
end
