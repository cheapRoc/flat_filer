require 'spec'
require 'pathname'
require Pathname(__FILE__).dirname.parent.join('lib', 'flat_file')

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


describe FlatFile, 'simple' do
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

  it "should have a PersonFile instance" do
    @person_file.should be_an_instance_of(PersonFile)
  end

  it "should know pad fields" do
    PersonFile.non_pad_fields.select do |f|
      f.is_padding?
    end.length.should be_zero
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

  it "should process records" do
    @person_file.each_record(@io) { |r,l| }
    @io.should be_eof
  end

  # In our flat file class above, the phone field
  # has a map_in_proc which does not overwrite the
  # attribute on the target model.
  #
  # A successful test will not overwrite the phone number.
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
