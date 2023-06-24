require 'redcarpet'
require 'nokogiri'

module Daifuku

  class Parser
    def parse(markdown_str, category_name)
      html_str = markdown.render(markdown_str)
      html = Nokogiri::HTML(html_str).css('body')

      top_level_nodes = html.children
      nodes_per_event = {}
      common_columns_nodes = []
      current_event_name = nil
      top_level_nodes.each do |node|
        case node.name
        when 'h2'
          current_event_name = node.content
        when 'p', 'ul'
          if current_event_name
            nodes_per_event[current_event_name] ||= []
            nodes_per_event[current_event_name] << node
          else
            common_columns_nodes << node
          end
        else
          next
        end
      end

      events = nodes_per_event.map { |name_with_annotation, nodes|
        event = parse_event(name_with_annotation, nodes)
        [event.name, event]
      }.to_h
      common_event = parse_event(nil, common_columns_nodes)
      descriptions = common_event&.descriptions || []
      Category.new(category_name, events, descriptions, common_event&.columns || [])
    end

    private

    def parse_event(event_name, nodes)
      if event_name_match = event_name&.match(/\s*\[obsolete\]\s*(.*)/)
        event_name = event_name_match[1]
        is_obsolete = true
      else
        is_obsolete = false
      end
      descriptions = nodes.select { |node| node.name == 'p' }
                         .map { |node| node.content }
      columns_node = nodes.select { |node| node.name == 'ul' }.first
      columns = []
      columns = parse_columns(columns_node) if columns_node
      Event.new(event_name, columns, descriptions, is_obsolete)
    end

    def parse_columns(columns_node)
      descriptor_nodes = columns_node.css('> li')
      descriptor_nodes.map do |node|
        descriptor = node.content
        descriptions = node.css("ul li").map(&:content)
        column = Column.parse(descriptor, descriptions)
        raise "Could not parse '#{descriptor}'" unless column
        column
      end
    end

    def markdown
      @markdown ||= Redcarpet::Markdown.new(renderer, underline: false, emphasis: false)
    end

    def renderer
      @renderer ||= Daifuku::Renderer.new
    end
  end
end
