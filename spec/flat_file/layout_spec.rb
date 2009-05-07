require 'pathname'
require Pathname(__FILE__).dirname.parent.join('spec_helper')

describe FlatFile::Layout do

  context 'being added' do

    before :all do
      LayoutClass     = Class.new FlatFile
      @default_layout = LayoutClass.layout :some_layout do
        add_field :bacon_bits
      end
    end

    it "should return a new instance" do
      @default_layout.should be_an_instance_of(FlatFile::Layout)
    end
    
    it "should add to the list of layouts" do
      @default_layout.parent.layouts.should include(@default_layout)
    end

    it "should set its name" do
      @default_layout.name.should == :some_layout
    end

    it "should set its parent" do
      @default_layout.parent.should == LayoutClass
    end

    it "should set a field in its field class" do
      @default_layout.field_class.fields.first.name.should == :bacon_bits
    end
    
    it "should define an anonymous class for fields" do
      @default_layout.field_class.should be_an_instance_of(Class)
    end

    it "should inherit FlatFile for its field class" do
      @default_layout.field_class.ancestors.should include(FlatFile)
    end

  end

end
