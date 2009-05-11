require 'pathname'
require Pathname(__FILE__).dirname.parent.join('spec_helper')

describe FlatFile::FieldDef do

  context 'being added' do

    before :all do
      FieldDefClass     = Class.new FlatFile
      @default_field = FieldDefClass.add_field :some_field
    end
    
    it "should return a new instance" do
      @default_field.should be_an_instance_of(FlatFile::FieldDef)
    end

    it "should set its name" do
      @default_field.name.should == :some_field
    end

    it "should set a width of 10" do
      @default_field.width.should == 10
    end

    it "should have empty filters" do
      @default_field.filters.should be_empty
    end
    
    it "should have no padding" do
      @default_field.padding.should be_nil
    end

    it "should have the master class as the file_klass" do
      @default_field.file_klass.should == FieldDefClass
    end

    it "should not be aggressive" do
      @default_field.aggressive.should be_false
    end

    it "should not have a map_in_proc" do
      @default_field.map_in_proc.should be_nil
    end

    it "should be added to the parent classes fields" do
      FieldDefClass.fields.should include(@default_field)
    end

    it "should add 'A10' to the parent class pack format for each field" do
      FieldDefClass.pack_format.should == "A10" * FieldDefClass.fields.size
    end

    it "should add '10' to the parent class width" do
      lambda {
        FieldDefClass.add_field(:field_3)
      }.should change(FieldDefClass, :width).by(10)
    end

  end

end
