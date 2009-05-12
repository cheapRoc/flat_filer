class FlatFile #:nodoc:
  # A record abstracts on line or 'record' of a fixed width field.
  # The methods available are the keys of the hash passed to the constructor.
  # For example the call:
  #
  #  h = Hash['first_name','Andy','status','Supercool!']
  #  r = Record.new(h)
  #
  # would respond to r.first_name, and r.status yielding
  # 'Andy' and 'Supercool!' respectively.
  #
  class Record

    attr_reader \
      :fields,
      :klass,
      :line_number

    #
    # Create a new Record from a hash of fields
    #
    def initialize klass, fields=Hash.new, line_number=-1, &block
      @fields, @klass, @line_number = fields, klass, line_number

      @fields = klass.fields.inject({}) do |map, field|
        klass.has_field?(field.name) ?
          map.update(field.name => fields[field.name]) : map
      end

      yield block, self if block_given?

      return self
    end

    def map_in model
      @klass.non_pad_fields.each do |f|
        next unless model.respond_to?("#{f.name}=")
        if f.map_in_proc
          f.map_in_proc.call(model, self)
        else
          if f.aggressive || model.send(f.name).nil? || model.send(f.name).empty?
            model.send("#{f.name}=", send(f.name))
          end
        end
      end
    end

    #
    # Catches method calls and returns field values or raises an Error.
    #
    def method_missing method, params=nil
      if method.to_s =~ /^(.*)=$/
        if fields.has_key?($1.to_sym)
          @fields.store($1.to_sym, params)
        else
          raise StandardError, "Unknown method: #{method}"
        end
      else
        if fields.has_key?(method)
          @fields.fetch(method)
        else
          raise StandardError, "Unknown method: #{method}"
        end
      end
    end

    #
    # Returns a string representation of the record suitable for writing to a flat
    # file on disk or other media.  The fields are prepared according to the file
    # definition, and any formatters attached to the field definitions.
    #
    def to_s
      klass.fields.map do |field_def|
        field_name = field_def.name.to_s
        value = @fields[field_name.to_sym]
        field_def.pass_through_formatters(field_def.is_padding? ? "" : value)
      end.pack(klass.pack_format)
    end

    # Produces a multiline string, one field per line suitable for debugging purposes.
    def debug_string
      klass.fields.inject('') do |str, field|
        str << "#{f.name}: #{send(f.name.to_sym) if f.is_padding?}\n"
      end
    end

  end
end
