# frozen_string_literal: true

module CSA
  module WarningFilter
    SUPPRESSED_WARNINGS = [
      'Top level ::CompositeIO is deprecated',
      'Top level ::Parts is deprecated'
    ].freeze

    module_function

    def activate!
      return if @activated

      Warning.singleton_class.class_eval do
        alias_method :csa_original_warn, :warn

        define_method(:warn) do |*args, **kwargs|
          message = args.first
          return if CSA::WarningFilter.suppressed?(message)

          if kwargs.empty?
            csa_original_warn(*args)
          else
            csa_original_warn(*args, **kwargs)
          end
        end
      end

      @activated = true
    end

    def suppressed?(message)
      return false unless message

      SUPPRESSED_WARNINGS.any? { |needle| message.include?(needle) }
    end
  end
end
