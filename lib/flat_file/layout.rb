class FlatFile #:nodoc:
  # A layout allows multiple sub-flat file formats to be defined
  # within a single class.
  class Layout

    class ConstructorError < StandardError; end

    attr_reader \
      :name,
      :rows,
      :parent,
      :field_class

    def initialize name, options={}, parent=nil, field_proc=nil
      if parent && field_proc
        @name       = name
        @parent     = parent
        @rows       = options[:rows]
        @field_proc = field_proc
      else
        raise ConstructorError, 'No parent and/or field_proc'
      end
    end

    def field_class
      @field_class ||= Class.new FlatFile, &field_proc
    end

    private

    def field_proc
      @field_proc
    end
   
  end
end
