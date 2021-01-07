# frozen_string_literal: true

require 'phony'

module MoteSMS
  # MoteSMS::Number handles all the number parsing and formatting
  # issues, also a number is immutable.
  class Number
    # Support both Phony 1.7 and 2.x
    PhonyError = begin
      Phony::NormalizationError
    rescue StandardError
      Class.new(ArgumentError)
    end

    # Access the E164 normalized value of the number.
    attr_reader :number
    alias to_number number

    def initialize(value, options = {})
      @options = options || {}
      @raw_number = value.to_s
      parse_raw_number
    end

    # Public: Returns true if this **could** represent a vanity number.
    #
    # Returns Boolean, true if this is a vanity number, else false.
    def vanity?
      !!@options[:vanity]
    end

    # Public: Prints formatted number, i.e. the human readable
    # variant.
    #
    # Returns formatted number.
    def to_s
      @formatted_number ||= vanity? ? number : Phony.formatted(number)
    end

    protected

    # Internal: Parse raw number with the help of Phony. Automatically
    # adds the country code if missing.
    #
    def parse_raw_number
      if vanity?
        @number = @raw_number.gsub(/[^A-Z0-9]/i, '').upcase.strip
        raise ArgumentError, "Invalid vanity number #{@raw_number}" if @number.length.zero? || @number.length > 11
      else
        unless @raw_number.to_s =~ %r{\A[\d./\-\s()+]+\z}
          raise ArgumentError,
                "Unable to parse #{@raw_number} as number"
        end

        cc = @options[:cc]
        normalized = Phony.normalize(@raw_number)
        normalized = "#{cc}#{normalized}" unless cc && normalized.start_with?(cc)
        raise ArgumentError, "Wrong national destination code #{@raw_number}" unless Phony.plausible?(normalized,
                                                                                                      @options)

        @number = Phony.normalize normalized
      end
    rescue PhonyError => e
      raise ArgumentError, "Phony: #{e}"
    rescue NoMethodError
      raise ArgumentError, "Unable to parse #{@raw_number} using phony"
    end
  end
end
