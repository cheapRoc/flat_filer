require 'pathname'
require Pathname(__FILE__).dirname.join('spec_helper')

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
      FlatClass.subclass_data.should have_key(:fields)
    end

    it "should store the pack format within the subclass data" do
      FlatClass.subclass_data.should have_key(:pack_format)
    end

    it "should store the width within the subclass data" do
      FlatClass.subclass_data.should have_key(:width)
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

  context 'inherited class instance with basic fields' do

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

  context "multiple lines" do 
  end

end
