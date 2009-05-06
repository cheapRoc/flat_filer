require 'spec'
require 'pathname'
require Pathname(__FILE__).dirname.parent.join('lib', 'flat_file')

class FlatClass < FlatFile; end

class PersonFile < FlatFile

  EXAMPLE_FILE = <<-EOF
1234567890123456789012345678901234567890
f_name    l_name              age pad---
Captain   Stubing             4      xxx
No        Phone               5      xxx
Has       Phone     11111111116      xxx

EOF

  add_field :f_name, :width => 10

  add_field :l_name, :width => 10, :aggressive => true

  add_field :phone, :width => 10,
    :map_in_proc => proc { |model, record|
      return if model.phone
      model.phone = record.phone
    }

  add_field :age, :width => 4,
    :filter => proc { |v| v.to_i },
    :formatter => proc { |v| v.to_f.to_s }

  pad :auto_name, :width => 3

  add_field :ignore, :width => 3, :padding => true

end

class PersonAddressFile < FlatFile

  EXAMPLE_FILE = <<-EOF
1234567890123456789012345678901234567890
People Recs CHEM-101   010109        xxx
1234567890123456789012345678901234567890
f_name    l_name              age pad---
Captain   Stubing             4      xxx
No        Phone               5      xxx
Has       Phone     11111111116      xxx

EOF
  
  layout :header, :rows => 1 do

    add_field :title, :width => 12

    add_field :department, :width => 10

    add_field :created_at, :width => 6

    pad :auto_name, :width => 5

    add_field :ignore, :width => 5, :padding => true

  end

  layout :person do

    add_field :f_name, :width => 10

    add_field :l_name, :width => 10, :aggressive => true

    add_field :phone, :width => 10,
      :map_in_proc => proc { |model, record|
        return if model.phone
        model.phone = record.phone
      }

    add_field :age, :width => 4,
      :filter => proc { |v| v.to_i },
      :formatter => proc { |v| v.to_f.to_s }

    pad :auto_name, :width => 3

    add_field :ignore, :width => 3, :padding => true

  end

end

describe FlatFile do
  
  context "inherited classes" do

    it "should have a list of fields" do
      FlatClass.fields.should be_an_instance_of(Array)
    end

    it "should have a pack format" do
      FlatClass.pack_format.should be_an_instance_of(String)
    end
    
    it "should have a zero width" do
      FlatClass.width.should be_zero
    end
    
    it "should have a subclass data map" do
      FlatClass.subclass_data.should be_an_instance_of(Hash)
    end

    it "should store the fields within the subclass data" do
      FlatClass.subclass_data.should have_key('fields')
    end

    it "should store the pack format within the subclass data" do
      FlatClass.subclass_data.should have_key('pack_format')
    end

    it "should store the width within the subclass data" do
      FlatClass.subclass_data.should have_key('width')
    end

    it "should add field :some_field" do
      FlatClass.add_field(:some_field).should be_an_instance_of(FlatFile::FieldDef) 
    end

    it "should have field :some_field" do
      FlatClass.should have_field(:some_field)
    end

    it "should pad with name :auto_name" do
      FlatClass.pad(:auto_name).should be_an_instance_of(FlatFile::FieldDef)
    end

    it "should be able to generate a unique new pad name" do
      FlatClass.new_pad_name.to_s.should =~ /pad_[0-9]*/
    end

    it "should have a list of non padded fields" do
      FlatClass.non_pad_fields.should be_an_instance_of(Array)
    end

    it "should not include pad fields when listing non padded fields" do
      FlatClass.non_pad_fields.should_not include(*FlatClass.fields.map {|f| f.padding})
    end

    it "should create a new record" do
      FlatClass.new_record.should be_an_instance_of(FlatFile::Record)
    end
    
  end

  context 'field definitions' do

    before :all do
      @default_field = FlatClass.add_field(:some_field)
    end
    
    it "should add fields as instances of FlatFile::FieldDef" do
      @default_field.should be_an_instance_of(FlatFile::FieldDef)
    end

    it "should have the supplied name" do
      @default_field.name.should == :some_field
    end

    it "should have filters as an instance of Array" do
      @default_field.filters.should be_an_instance_of(Array)
    end
    
    it "should have no filters" do
      @default_field.filters.should be_empty
    end

    it "should have no padding" do
      @default_field.padding.should be_nil
    end

    it "should have the master class as the file_klass" do
      @default_field.file_klass.should == FlatClass
    end

    it "should not be aggressive" do
      @default_field.aggressive.should be_false
    end

    it "should have a width of 10" do
      @default_field.width.should == 10
    end

    it "should not have a map_in_proc" do
      @default_field.map_in_proc.should be_nil
    end

    it "should add the field to the parent class fields Array" do
      FlatClass.fields.should include(@default_field)
    end

    it "should add 'A10' to the parent class pack format string" do
      FlatClass.pack_format.should == 'A10' * (FlatClass.width / 10)
    end

    it "should add '10' to the parent class width" do
      FlatClass.width.should == FlatClass.fields.inject(0) do |sum, field|
        sum += field.width
      end
    end

  end

  context 'inherited class instance' do

    before :all do
      @person_file = PersonFile.new      
      @data        = PersonFile::EXAMPLE_FILE
      @lines       = @data.split("\n")

      Struct.new "Person", :f_name, :l_name, :phone, :age, :ignore
    end

    before :each do
      @stream = StringIO.new(@data)
    end
    
    it "should have fields like its parent class" do
      @person_file.fields.should == PersonFile.fields
    end

    it "should list non padded fields like its parent class" do
      @person_file.non_pad_fields.should == PersonFile.non_pad_fields
    end
    
    it "should have a width like its parent class" do
      @person_file.width.should == PersonFile.width
    end
    
    it "should have a pack format like its parent class" do
      @person_file.pack_format.should == PersonFile.pack_format
    end
    
    it "should be able to create a record" do
      @person_file.create_record("Captain   Stubing   4         ").
        should be_an_instance_of(FlatFile::Record)
    end

    it "should iterate to the next record" do
      first_record = @person_file.next_record(@stream)
      @person_file.next_record(@stream).should_not == first_record
    end

    it "should iterate over each record" do
      record_count = 0
      @person_file.each_record(@stream) do
        record_count += 1
      end
      record_count.should == @lines.length
    end
    
    it "should reach end of file" do
      @person_file.each_record(@stream) { |r,l| }
      @stream.should be_eof
    end

    it "should honor filters when creating a record" do
      r = @person_file.create_record("Captain   Stubing   4         ")
      r.age.should be_an_instance_of(Fixnum)
    end

    it "should honor formatters when iterating each record" do
      @person_file.next_record(@stream)
      @person_file.next_record(@stream)
      @person_file.next_record(@stream) do |r, line_number|
        r.to_s.split(/\s+/)[2].should == '4.0'
      end
    end

    # NOTE: these are really FlatFile::Record specs, since they primarily use #map_in
    
    it "should overwrite given an aggressive field" do
      person = Struct::Person.new('A','Hole','5555555555','4')
      rec = @person_file.create_record(@lines[4])
      rec.map_in(person)
      person.l_name.should == "Phone"
    end

    it "should overwrite given a map in proc for a field" do
      person = Struct::Person.new('A','Hole','5555555555','4')
      rec = @person_file.create_record(@lines[4])
      rec.map_in(person)
      person.ignore.should be_nil
      person.f_name.should == "A"
    end

    it "should not overwrite without a map in proc for a field" do
      person = Struct::Person.new('A','Hole','5555555555','4')
      rec = @person_file.create_record(@lines[4])
      rec.map_in(person)
      person.phone.should == "5555555555"
    end

  end

  context 'multiple layouts' do

    before :all do
      @default_layout = FlatClass.layout :some_layout do
        add_field :bacon_bits
      end
      
      @person_address_file = PersonAddressFile.new
      @data                = PersonAddressFile::EXAMPLE_FILE
      @lines               = @data.split("\n")

      Struct.new "Address", :title, :department, :created_at, :auto_name, :ignore
      Struct.new "Person", :f_name, :l_name, :phone, :age, :ignore
    end

    it "should return a FlatFile::Layout" do
      @default_layout.should be_an_instance_of(FlatFile::Layout)
    end
    
    it "should add to the list of layouts" do
      @default_layout.parent.layouts.should include(@default_layout)
    end

    it "should have the supplied name" do
      @default_layout.name.should == :some_layout
    end

    it "should have defined an anonymous field class" do
      @default_layout.field_class.should be_an_instance_of(Class)
    end

    it "should have a field class which inherited FlatFile" do
      @default_layout.field_class.ancestors.should include(FlatFile)
    end

    it "should have a field class with 1 fields" do
      @default_layout.field_class.fields.size.should == 1
    end

  end

  context "multiple lines" do 
  end

end
