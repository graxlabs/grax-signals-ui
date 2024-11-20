module Scoring
  class JoinDefinition
    attr_reader :source, :alias_name, :condition, :join_type

    def initialize(source:, alias_name:, condition:, join_type: :left)
      @source = source
      @alias_name = alias_name
      @condition = condition
      @join_type = join_type
    end

    def to_sql
      "#{join_type_sql} JOIN #{source} #{alias_name} ON #{condition}"
    end

    private

    def join_type_sql
      case join_type
      when :left then "LEFT"
      when :inner then "INNER"
      when :right then "RIGHT"
      else raise "Unsupported join type: #{join_type}"
      end
    end
  end
end