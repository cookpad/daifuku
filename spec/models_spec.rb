require 'spec_helper'
include Daifuku

RSpec.describe 'Type#parse' do
  context 'built-in types' do
    it 'can parse a regular type' do
      type = Type.parse('!bigint')
      expect(type.name).to eql('bigint')
      expect(type.optional?).to be_falsey
      expect(type.custom?).to be_falsey
      expect(type.str_length).to be_nil
    end

    it 'can parse an optional type' do
      type = Type.parse('!integer?')
      expect(type.name).to eql('integer')
      expect(type.optional?).to be_truthy
      expect(type.custom?).to be_falsey
      expect(type.str_length).to be_nil
    end

    it 'can parse an optional type' do
      type = Type.parse('!integer?')
      expect(type.name).to eql('integer')
      expect(type.optional?).to be_truthy
      expect(type.custom?).to be_falsey
      expect(type.str_length).to be_nil
    end

    it 'can parse a string without length' do
      type = Type.parse('!string')
      expect(type.name).to eql('string')
      expect(type.optional?).to be_falsey
      expect(type.custom?).to be_falsey
      expect(type.str_length).to be_nil
    end

    context 'with length' do
      it 'can parse a string with length' do
        type = Type.parse('!string 128')
        expect(type.name).to eql('string')
        expect(type.optional?).to be_falsey
        expect(type.custom?).to be_falsey
        expect(type.str_length).to eql(128)
      end

      it 'can parse an optional string with length' do
        type = Type.parse('!string? 128')
        expect(type.name).to eql('string')
        expect(type.optional?).to be_truthy
        expect(type.custom?).to be_falsey
        expect(type.str_length).to eql(128)
      end

      it 'cannot parse an other type with length' do
        expect {
          Type.parse('!bigint 128')
        }.to raise_error("length for 'bigint' is not supported")
      end

    end

    it 'cannot parse an unknown type' do
      expect {
        Type.parse('!unknown_type')
      }.to raise_error("type_name 'unknown_type' is not allowed")
    end
  end

  context 'custom types' do
    it 'can parse a regular type' do
      type = Type.parse('MyType')
      expect(type.name).to eql('MyType')
      expect(type.optional?).to be_falsey
      expect(type.custom?).to be_truthy
    end

    it 'can parse an optional type' do
      type = Type.parse('MyType?')
      expect(type.name).to eql('MyType')
      expect(type.optional?).to be_truthy
      expect(type.custom?).to be_truthy
    end
  end
end

RSpec.describe Column do
  describe '#parse' do
    context 'with a regular typed column' do
      let(:column) { Column.parse('column0:!bigint', ['important column']) }
      it 'can parse' do
        expect(column.name).to eql('column0')
        expect(column.type.name).to eql('bigint')
        expect(column.descriptions).to eql(['important column'])
        expect(column.obsolete?).to be_falsey
      end

      context 'with [obsolete] annotation' do
        let(:column) { Column.parse('[obsolete] column0:!bigint', ['important column']) }
        it 'can parse' do
          expect(column.name).to eql('column0')
          expect(column.type.name).to eql('bigint')
          expect(column.descriptions).to eql(['important column'])
          expect(column.obsolete?).to be_truthy
        end
      end

      context 'with [obsolete] annotation without whitespaces' do
        let(:column) { Column.parse('[obsolete]column0:!bigint', ['important column']) }
        it 'can parse' do
          expect(column.name).to eql('column0')
          expect(column.type.name).to eql('bigint')
          expect(column.descriptions).to eql(['important column'])
          expect(column.obsolete?).to be_truthy
        end
      end
    end

    context 'with a optional typed column' do
      let(:column) { Column.parse('column0: !string?', ['important column']) }
      it 'can parse' do
        expect(column.name).to eql('column0')
        expect(column.type.name).to eql('string')
        expect(column.type.optional?).to be_truthy
        expect(column.descriptions).to eql(['important column'])
        expect(column.obsolete?).to be_falsey
      end

      it 'can parse a optional string column with length' do
        column = Column.parse('column0: !string? 256', ['important column'])
        expect(column.obsolete?).to be_falsey
      end
    end

    context 'with a optional string column with length' do
      let(:column) { Column.parse('column0: !string? 256', ['important column']) }
      it 'can parse' do
        expect(column.name).to eql('column0')
        expect(column.type.name).to eql('string')
        expect(column.type.optional?).to be_truthy
        expect(column.type.custom?).to be_falsey
        expect(column.type.str_length).to eql(256)
        expect(column.descriptions).to eql(['important column'])
      end

      context 'with an unknown typed column' do
        it 'cannot parse' do
          expect {
            Column.parse('column0:!unknown', 'important column')
          }.to raise_error("type_name 'unknown' is not allowed")
        end
      end

      context 'with an invalid descriptor' do
        it 'cannot parse' do
          expect {
            Column.parse('XXXXXXX', 'important column')
          }.to raise_error("Could not parse column 'XXXXXXX'")
        end
      end
    end
  end

  describe '#strdef' do
    let(:column) { Column.new('column', type, 'dummy') }
    context 'with general type' do
      let(:type) { Type.new('integer', false, false, nil) }
      it { expect(column.strdef).to eql('column: !integer') }
    end

    context 'with custom type' do
      let(:type) { Type.new('MyClass', false, true, nil) }
      it { expect(column.strdef).to eql('column: MyClass') }
    end

    context 'with string type with length' do
      let(:type) { Type.new('string', false, false, 1024) }
      it { expect(column.strdef).to eql('column: !string 1024') }
    end
  end
end

RSpec.describe Category do
  describe '#dump' do
    let(:category) {
      Category.new('category', events, 'descriptions', [])
    }
    let(:events) {
      { 'event' => Event.new('event', columns, 'descriptions', false) }
    }
    let(:columns) {
      [Column.parse('column0: !string? 256', ['important column'])]
    }

    it { expect { category.dump }.not_to raise_error }
  end
end

