class FlatFile #:nodoc:
  # A layout allows multiple sub-flat file formats to be defined
  # within a single class.
  class Layout

    attr_reader \
      :name,
      :rows,
      :parent,
      :field_class
    
    def initialize(name, options={}, parent=nil, field_proc=nil)
      @name, @parent, @rows = name, parent, options[:rows]
      @field_class = Class.new(FlatFile, &field_proc)
    end
    
  end
end
