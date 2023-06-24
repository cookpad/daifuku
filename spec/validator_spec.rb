require 'spec_helper'
include Daifuku

RSpec.describe 'Validator#validate!' do
  let(:validator) { Validator.new(rules) }
  let(:string) { Type.new('string', false, false) }
  let(:optional_string) { Type.new('string', true, false) }
  let(:string_with_length) { Type.new('string', false, false, 64) }
  let(:bigint) { Type.new('bigint', false, false) }

  describe ShadowingRule do
    let(:rules) { [ShadowingRule.new] }

    context 'with same named columns with common columns' do
      let(:categories) {
        {
            'common' => Category.new('common', [], '', [Column.new('recipe_id', bigint, [])]),
            'my_category' => Category.new('my_category', {
                'my_event0' => Event.new('my_event0', [Column.new('recipe_id', bigint, [])], '', false)
            }, '', []),
        }
      }

      it 'raises error' do
        expect {
          validator.validate!(categories)
        }.to raise_error("Column 'recipe_id' on 'my_category' is already defined on common columns")
      end
    end

    context 'with different named columns with common columns' do
      let(:categories) {
        {
            'common' => Category.new('common', [], '', [Column.new('recipe_id', bigint, [])]),
            'my_category' => Category.new('my_category', {
                'my_event0' => Event.new('my_event0', [Column.new('tsukurepo_id', bigint, [])], '', false)
            }, '', []),
        }
      }

      it 'should not raise errors' do
        expect {
          validator.validate!(categories)
        }.not_to raise_error
      end
    end
  end

  describe ReservedColumnsRule do
    let(:rules) { [ReservedColumnsRule.new] }
    context 'with reserved names columns' do
      let(:categories) {
        {
            'my_category1' => Category.new('my_category1', {
                'my_event0' => Event.new('my_event0', [Column.new('event_name', string, [])], '', false)
            }, '', []),
        }
      }

      it 'raises error' do
        expect {
          validator.validate!(categories)
        }.to raise_error("'event_name' is reserved")
      end
    end

    context 'with not reserved names columns' do
      let(:categories) {
        {
            'common' => Category.new('common', {}, '', [Column.new('recipe_id', bigint, [])]),
            'my_category' => Category.new('my_category', {
                'my_event0' => Event.new('my_event0', [Column.new('tsukurepo_id', bigint, [])], '', false)
            }, '', []),
        }
      }

      it 'should not raise errors' do
        expect {
          validator.validate!(categories)
        }.not_to raise_error
      end
    end
  end

  describe MultipleTypesRule do
    let(:rules) { [MultipleTypesRule.new] }
    context 'with same named columns with multiple types' do
      let(:categories) {
        {
            'my_category1' => Category.new('my_category1', {
                'my_event0' => Event.new('my_event0', [Column.new('recipe_id', string, [])], '', false)
            }, '', []),
            'my_category2' => Category.new('my_category2', {
                'my_event0' => Event.new('my_event0', [Column.new('recipe_id', bigint, [])], '', false)
            }, '', []),
        }
      }

      it 'raises error' do
        expect {
          validator.validate!(categories)
        }.to raise_error("Multiple types are found for 'recipe_id'")
      end
    end

    context 'with same named columns with same types' do
      let(:categories) {
        {
            'my_category1' => Category.new('my_category1', {
                'my_event0' => Event.new('my_event0', [Column.new('recipe_id', string, [])], '', false)
            }, '', []),
            'my_category2' => Category.new('my_category2', {
                'my_event1' => Event.new('my_event0', [Column.new('recipe_id', string, [])], '', false)
            }, '', []),
        }
      }

      it 'should be valid' do
        expect {
          validator.validate!(categories)
        }.not_to raise_error
      end
    end

    context 'with same named columns with multiple optional types' do
      let(:categories) {
        {
            'my_category1' => Category.new('my_category1', {
                'my_event0' => Event.new('my_event0', [Column.new('recipe_id', string, [])], '', false)
            }, '', []),
            'my_category2' => Category.new('my_category2', {
                'my_event0' => Event.new('my_event0', [Column.new('recipe_id', optional_string, [])], '', false)
            }, '', []),
        }
      }

      it 'raises error' do
        expect {
          validator.validate!(categories)
        }.not_to raise_error
      end
    end

    context 'with same named columns with multiple string length' do
      let(:categories) {
        {
            'my_category1' => Category.new('my_category1', {
                'my_event0' => Event.new('my_event0', [Column.new('name', string, [])], '', false)
            }, '', []),
            'my_category2' => Category.new('my_category2', {
                'my_event0' => Event.new('my_event0', [Column.new('name', string_with_length, [])], '', false)
            }, '', []),
        }
      }

      it 'raises error' do
        expect {
          validator.validate!(categories)
        }.to raise_error("Multiple types are found for 'name'")
      end
    end
  end

  describe NameLengthRule do
    let(:rules) { [NameLengthRule.new(64)] }
    let(:category_name) { 'valid_category' }
    let(:event_name) { 'valid_event' }
    let(:column_name) { 'valid_column' }
    let(:categories) {
      {
          category_name => Category.new(category_name, {
              event_name => Event.new(event_name, [Column.new(column_name, string, [])], '', false)
          }, '', []),
      }
    }
    context 'with long category names' do
      let(:category_name) { 'a' * 65 }

      it 'raises violations' do
        expect {
          validator.validate!(categories)
        }.to raise_error("#{category_name} must be within 64 characters.")
      end
    end

    context 'with long event names' do
      let(:event_name) { 'a' * 65 }

      it 'raises violations' do
        expect {
          validator.validate!(categories)
        }.to raise_error("valid_category.#{event_name} must be within 64 characters.")
      end
    end

    context 'with long column names' do
      let(:column_name) { 'a' * 65 }

      it 'raises violations' do
        expect {
          validator.validate!(categories)
        }.to raise_error("valid_category.valid_event.#{column_name} must be within 64 characters.")
      end
    end

  end
end
