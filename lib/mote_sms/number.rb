require 'phony'

module MoteSMS

  # MoteSMS::Number handles all the number parsing and formatting
  # issues, also a number is immutable.
  class Number

    # Access the E164 normalized value of the number.
    attr_reader :number
    alias :to_number :number

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
      unless vanity?
        raise ArgumentError, "Unable to parse #{@raw_number} as number" unless Phony.plausible?(@raw_number)
        normalized = Phony.normalize(@raw_number)
        normalized = "#{@options[:cc]}#{normalized}" unless @options[:cc] && normalized.start_with?(@options[:cc])
        raise ArgumentError, "Wrong national destination code #{@raw_number}" unless Phony.plausible?(normalized, @options)

        @number = Phony.normalize normalized
      else
        @number = @raw_number
      end
    end
  end
end
