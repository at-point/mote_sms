require 'mote_sms/number'

module MoteSMS

  # List of Number instances, which transparantly is able to add
  # new Number instances from strings, or whatever.
  #
  # Implements Enumerable, thus can be used like any regular array.
  #
  # Examples:
  #
  #    list << '+41 79 123 12 12'
  #    list.push '044 123 12 12', cc: '41'
  #    list.push Number.new('0800 123 12 12')
  #    list.normalized_numbers
  #    # => ['41791231212', '41441231212', '08001231212']
  #
  class NumberList

    # Load ruby enumerable support.
    include ::Enumerable

    # Internal numbers array.
    attr_reader :numbers

    # Public: Create a new number list instance.
    def initialize
      @numbers = ::Array.new
    end

    # Public: Count of numbers in the list.
    def length
      numbers.length
    end
    alias :size :length

    # Public: Conform to arrayish behavior.
    def empty?
      numbers.empty?
    end
    alias :blank? :empty?

    # Public: Add number to internal list, use duck typing to detect if
    # it appears to be a number instance or not. So everything which does
    # not respond to `to_number` is converted into a Number instance.
    #
    # number - The Number or String to add.
    #
    # Returns nothing.
    def <<(number)
      self.push(number)
    end

    # Public: Add multiple numbers, with optional options hash which can
    # be used to set country options etc.
    #
    # Returns self.
    def push(*numbers)
      options = numbers.last.is_a?(Hash) ? numbers.pop : {}
      numbers.flatten.each do |number|
        number = Number.new(number, options) unless number.respond_to?(:to_number)
        self.numbers << number
      end
      self
    end

    # Public: Yields each Number instance from this number list
    # to the provided block. This interface is also required to be
    # implemeneted for Enumerable support.
    #
    # Returns self.
    def each(&block)
      numbers.each(&block)
      self
    end

    # Public: Fetch numbers using to_number.
    #
    # Returns Array of E164 normalized numbers.
    def normalized_numbers
      numbers.map(&:to_number)
    end
  end
end
