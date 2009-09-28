class FlatFile #:nodoc:
  #
  # A field definition tracks information that's necessary for
  # FlatFile to process a particular field.  This is typically
  # added to a subclass of FlatFile like so:
  #
  #  class SomeFile < FlatFile
  #    add_field :some_field_name, :width => 35
  #  end
  #
  class FieldDef

    attr_accessor \
      :name,
      :width,
      :filters,
      :formatters,
      :parent,
      :padding,
      :map_in_proc,
      :aggressive

    alias file_klass parent
    
    #
    # Create a new FieldDef, having name and width. klass is a reference to the
    # FlatFile subclass that contains this field definition.  This reference is
    # needed when calling filters if they are specified using a symbol.
    #
    # Options can be :padding (if present and a true value, field is marked as a
    # pad field), :width, specify the field width, :formatter, specify a formatter,
    # :filter, specify a filter.
    #
    def initialize name=null, options={}, klass={}
      @name = name
      @width = options[:width] || 10
      @filters = @formatters = Array.new
      @parent = klass
      @padding = options[:padding]

      add_filter(options[:filter])
      add_formatter(options[:formatter])

      @map_in_proc = options[:map_in_proc]
      @aggressive = options[:aggressive] || false
    end

    #
    # Will return true if the field is a padding field.  Padding fields are ignored
    # when doing various things. For example, if/when you're populating an ActiveRecord
    # model with a record, padding fields are ignored.
    #
    def is_padding?
      @padding
    end

    #
    # Add a filter. Filters are used for processing field data when a flat file is
    # being processed. For fomratting the data when writing a flat file, see
    # add_formatter
    #
    def add_filter filter=nil, &block
      @filters.push(filter) if filter
      @filters.push(block) if block_given?
    end

    #
    # Add a formatter. Formatters are used for formatting a field
    # for rendering a record, or writing it to a file in the desired format.
    #
    def add_formatter(formatter=nil,&block) #:nodoc:
      @formatters.push(formatter) if formatter
      @formatters.push(block) if block_given?
    end

    # Filters a value based on teh filters associated with a
    # FieldDef.
    def pass_through_filters v
      pass_through @filters, v
    end

    # Filters a value based on the filters associated with a
    # FieldDef.
    def pass_through_formatters v
      pass_through @formatters, v
    end

    def pass_through(type)
      pass_through
    end

    #protected

    def pass_through what, value
      #puts "PASS THROUGH #{what.inspect} => #{value}"
      what.each do |filter|
        value = case
        when Symbol
          @parent.send(filter, value)
        when filter_block?(filter)
          filter.call(value)
        when filter_class?(filter)
          filter.filter(value)
        else
          value
        end
      end
      value
    end

    #
    # Test to see if filter is a filter block.  A filter block
    # can be called (using call) and takes one parameter
    #
    def filter_block?(filter)
      filter.respond_to?('call') && ( filter.arity >= 1 || filter.arity <= -1 )
    end

    #
    # Test to see if a class is a filter class.  A filter class responds
    # to the filter signal (you can call filter on it).
    #
    def filter_class?(filter)
      filter.respond_to?('filter')
    end

  end
end
