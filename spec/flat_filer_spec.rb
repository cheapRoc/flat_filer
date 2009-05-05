require 'spec'
require 'pathname'
require Pathname(__FILE__).dirname.parent.join('lib', 'flat_file')

class FlatClass < FlatFile; end

describe FlatFile, "inherited Classes" do

  it "should provide a fields list" do
    FlatClass.fields.should be_an_instance_of(Array)
  end

  it "should provide a pack format string" do
    FlatClass.pack_format.should be_an_instance_of(String)
  end
  
  it "should provide a zero width" do
    FlatClass.width.should be_zero
  end
  
  it "should provide a subclass data map" do
    FlatClass.subclass_data.should be_an_instance_of(Hash)
  end

  it "should store fields within the subclass data" do
    FlatClass.subclass_data.should have_key('fields')
  end

  it "should store pack format within the subclass data" do
    FlatClass.subclass_data.should have_key('pack_format')
  end

  it "should store total width within the subclass data" do
    FlatClass.subclass_data.should have_key('width')
  end

  it "should be able to add a field" do
    FlatClass.add_field(:some_field).should be_an_instance_of(FlatFile::FieldDef) 
  end

  it "should be able to add a pad" do
    FlatClass.pad(:auto_name).should be_an_instance_of(FlatFile::FieldDef)
  end

  it "should be able to generate a unique new pad name" do
    FlatClass.new_pad_name.to_s.should =~ /pad_[0-9]*/
  end

  it "should be able to create a record" do
    FlatClass.new_record.should be_an_instance_of(FlatFile::Record)
  end

  it "should provide a list of non padded fields" do
    FlatClass.non_pad_fields.should be_an_instance_of(Array)
  end

  it "should have a field" do
    FlatClass.should have_field(:some_field)
  end

end

describe FlatFile, 'inherited Class instances' do

  @@data = <<EOF
1234567890123456789012345678901234567890
f_name    l_name              age pad---
Captain   Stubing             4      xxx
No        Phone               5      xxx
Has       Phone     11111111116      xxx

EOF

  @@lines = @@data.split("\n")

  before :each do
    @flat_class = FlatClass.new
    @stream = StringIO.new(@@data)
  end

  describe 'adding a default field' do

    before :all do
      @default_field = FlatClass.add_field(:some_field)
    end
    
    it "should return a new FieldDef" do
      @default_field.should be_an_instance_of(FlatFile::FieldDef)
    end

    it "should have the supplied name" do
      @default_field.name.should == :some_field
    end

    it "should have an instance of Array for filters" do
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

    it "should be added to the parent class's fields Array" do
      FlatClass.fields.should include(@default_field)
    end
    
    it "should set a pack format string based on the number of fields" do
      FlatClass.pack_format.should == ('A10' * FlatClass.width.divmod(10)[0])
    end

    it "should add to the total width of the parent class" do
      FlatClass.width.should == FlatClass.fields.inject(0) do |sum, field|
        sum += field.width
      end + 10
    end

  end
end

class PersonFile < FlatFile

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


describe FlatFile, 'processing a file' do

  @@data = <<EOF
1234567890123456789012345678901234567890
f_name    l_name              age pad---
Captain   Stubing             4      xxx
No        Phone               5      xxx
Has       Phone     11111111116      xxx

EOF

  @@lines = @@data.split("\n")
  
  before :all do
    Struct.new("Person", :f_name, :l_name, :phone, :age, :ignore)
    @person_file = PersonFile.new
  end

  before :each do
    @io = StringIO.new(@@data)
  end

  it "should honor formatters" do
    @person_file.next_record(@io)
    @person_file.next_record(@io)
    @person_file.next_record(@io) do |r, line_number|
      r.to_s.split(/\s+/)[2].should == '4.0'
    end
  end

  it "should honor filters" do
    r = @person_file.create_record("Captain   Stubing   4         ")
    r.age.should be_an_instance_of(Fixnum)
  end

  it "should reach end of file" do
    @person_file.each_record(@io) { |r,l| }
    @io.should be_eof
  end

  it "should not overwrite according to map proc" do
    person = Struct::Person.new('A','Hole','5555555555','4')
    rec = @person_file.create_record(@@lines[4])
    rec.map_in(person)
    person.phone.should == "5555555555"
  end

  it "should overwrite when agressive" do
    person = Struct::Person.new('A','Hole','5555555555','4')
    rec = @person_file.create_record(@@lines[4])
    rec.map_in(person)
    person.l_name.should == "Phone"
  end

  it "should overwrite according to map proc" do
    person = Struct::Person.new('A','Hole','5555555555','4')
    rec = @person_file.create_record(@@lines[4])
    rec.map_in(person)
    person.ignore.should be_nil
    person.f_name.should == "A"
  end

  it "should process all lines in a file" do
    num_lines = @@data.split("\n").size + 1
    count = 0

    @io.each_line do
      count += 1
    end

    count.should == num_lines
  end
end

# class HeaderAndPersonFile < FlatFile

#   layout :header do

#     add_field :title, :width => 12

#     add_field :department, :width => 10

#     add_field :created_at, :width => 6

#     pad :auto_name, :width => 5

#     add_field :ignore, :width => 5, :padding => true

#   end

#   layout :person do

#     add_field :f_name, :width => 10

#     add_field :l_name, :width => 10, :aggressive => true

#     add_field :phone, :width => 10,
#     :map_in_proc => proc { |model, record|
#       return if model.phone
#       model.phone = record.phone
#     }

#     add_field :age, :width => 4,
#     :filter => proc { |v| v.to_i },
#     :formatter => proc { |v| v.to_f.to_s }

#     pad :auto_name, :width => 3

#     add_field :ignore, :width => 3, :padding => true

#   end

# end

describe FlatFile, 'layouts' do

  before :all do
    @@data = <<-EOF
1234567890123456789012345678901234567890
People Recs CHEM-101   010109        xxx
1234567890123456789012345678901234567890
f_name    l_name              age pad---
Captain   Stubing             4      xxx
No        Phone               5      xxx
Has       Phone     11111111116      xxx

EOF
  end

end
