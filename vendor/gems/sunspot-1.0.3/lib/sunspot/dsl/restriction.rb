module Sunspot
  module DSL
    # 
    # This class presents an API for building restrictions in the query DSL. The
    # methods exposed are the snake-cased names of the classes defined in the
    # Sunspot::Restriction module, with the exception of Base. All
    # methods take a single argument, which is the value to be applied to the
    # restriction.
    #
    class Restriction
      def initialize(field_name, query, negative) #:nodoc:
        @field_name, @scope, @negative = field_name, query, negative
      end

      Sunspot::Query::Restriction.names.each do |class_name|
        method_name = Util.snake_case(class_name.to_s)
        module_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def #{method_name}(value)
            @scope.add_restriction(@field_name, Sunspot::Query::Restriction::#{class_name}, value, @negative)
          end
        RUBY
      end
    end
  end
end
