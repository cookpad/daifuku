require 'spec_helper'

include Daifuku

RSpec.describe Parser do
  let(:parser) { Parser.new }
  let(:name) { 'my_category' }
  let(:category) { parser.parse(markdown.strip, name) }

  describe '#parse' do
    context 'with an event' do
      let(:markdown) {
        <<-MARKDOWN
## event1

- column0: !string
        MARKDOWN
      }
      it 'can parse definitions' do
        expect(category.name).to eql(name)
        expect(category.descriptions).to be_empty
        expect(category.events.size).to eql(1)
      end
    end

    context 'with multiple column descriptions' do
      let(:markdown) {
        <<-MARKDOWN
## event1

- column0: !string
  - Description1
  - Description2
- column1: !string
  - Description3
        MARKDOWN
      }
      it 'can parse definitions' do
        expect(category.name).to eql(name)
        expect(category.descriptions).to be_empty
        expect(category.events.size).to eql(1)
        expect(category.events['event1'].columns[0].descriptions).to eql(['Description1', 'Description2'])
        expect(category.events['event1'].columns[1].descriptions).to eql(['Description3'])
      end
    end

    context 'with multiple events' do
      let(:markdown) {
        <<-MARKDOWN
## event1

- column0: !string

## event2

- column1: !string
        MARKDOWN
      }
      it 'can parse definitions' do
        expect(category.name).to eql(name)
        expect(category.descriptions).to be_empty
        expect(category.events.size).to eql(2)
      end
    end

    context 'with common columns' do
      let(:markdown) {
        <<-MARKDOWN
- user_id: !bigint

## event1

- column0: !string

## event2

- column1: !string
        MARKDOWN
      }
      it 'can parse definitions' do
        expect(category.name).to eql(name)
        expect(category.descriptions).to be_empty
        expect(category.events.size).to eql(2)
        expect(category.common_columns.size).to eql(1)
      end
    end

    context 'with descriptions' do
      let(:markdown) {
        <<-MARKDOWN
Description of this category

Next Line

- user_id: !bigint

## event1

Description of event1

- column0: !string

## event2

Description of event2

More detail

- column1: !string
        MARKDOWN
      }
      it 'can parse definitions' do
        expect(category.name).to eql(name)
        expect(category.events.size).to eql(2)
        expect(category.common_columns.size).to eql(1)
        expect(category.descriptions).to eql(['Description of this category', 'Next Line'])
        expect(category.events['event1'].descriptions).to eql(['Description of event1'])
        expect(category.events['event2'].descriptions).to eql(['Description of event2', 'More detail'])
      end
    end

    context 'event marked as obsolete' do
      let(:markdown) {
        <<-MARKDOWN
## [obsolete] event1

- column0: !string

## event2

- column1: !string
        MARKDOWN
      }
      it 'can parse definitions' do
        expect(category.name).to eql(name)
        expect(category.events.size).to eql(2)
        expect(category.events['event1'].obsolete?).to be_truthy
        expect(category.events['event2'].obsolete?).to be_falsy
        expect(category.events['event1'].name).to eql('event1')
      end
    end

  end
end
