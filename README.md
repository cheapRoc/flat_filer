Flat Filer
==========

What
----

Flat Filer was made to easily access records formatted as fixed
width separated values. By providing an API for writing classes
which map these values to simple Ruby objects.

Why
---

Flat files are plain/mixed text, and/or binary, files which
normally contain one record per physical line. Within each
record or line the single fields (think columns) can be
separated by delimiters, e.g. commas, or have a fixed length
or width.

For records stored as fixed width, padding may be needed to
achieve these plain text delimitations. Extra whitespace, and/or
formatting, may be needed to avoid delimiter collision between
column values.

Normally a single file represents a single database "table".

Some call these Delimiter-separated values (DSVs). Most
developers are acquanted with their in-laws, the Comma-
separated value files (CSVs).

Where
-----

For example, a flat filer class for grabbing information about
people might look like this.

    # Actual plain text, flat file data
    #
    # 10 20 30
    # 012345678901234567890123456789
    # Walt      Whitman   18190531
    # Linus     Torvalds  19691228

    class People < FlatFile

      add_field :first_name, :width => 10, :filter => :trim

      add_field :last_name, :width => 10, :filter => :trim

      add_field :birthday, :width => 8, :filter => lambda { |v| Date.parse(v) }

      pad :auto_name, :width => 2,

      def self.trim(v)
        v.trim
      end
      
    end
  
    p = People.new
     
    p.each_record(open('somefile.dat')) do |person|
      
      puts "First Name: #{person.first_name}"
      puts "Last Name : #{person.last_name}"
      puts "Birthday : #{person.birthday}"

    puts person.to_s

An alternative method for adding fields is to pass a block to the
add_field method. The name is optional, but needs to be set either
by passing the name parameter, or in the block that's passed. When
you pass a block the first parameter is the FieldDef for the field
being constructed for this field.

    class People < FlatFile

      add_field do |fd|
        fd.name = :first_name
        fd.width = 10
        fd.add_filter { |v| v.trim }
        fd.add_formatter { |v| v.trim }
        # ...
      end
      
    end

Reference the Rdocs for more information, as well as how to
implement Filters and Formatters.

When
----

We use Flat Filer in production and it scratches our itch.

How
---

Flat Filer - Tue Apr 15 12:27:50 EDT 2008

This software is published under the MIT license:

The MIT License

Copyright (c) 2007-2009 Kinetic Web Solutions and Tangeis, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
