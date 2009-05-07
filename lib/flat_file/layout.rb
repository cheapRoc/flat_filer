class FlatFile #:nodoc:
  # A layout allows multiple sub-flat file formats to be defined
  # within a single class.
  class Layout

    class ConstructorError < StandardError
      def to_s
        'No parent and/or field_proc?'
      end
    end 

    attr_reader \
      :name,
      :rows,
      :parent,
      :field_class

    def initialize(name, options={}, parent=nil, field_proc=nil)
      raise ConstructorError unless parent && field_proc

      @name, @parent, @rows = name, parent, options[:rows]
      @field_class = Class.new(FlatFile, &field_proc)
    end
    
  end
end
