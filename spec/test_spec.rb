require 'spec_helper'

describe 'om stuff' do
  class TestTerminology
    include OM::XML::Document

    set_terminology do |t|
      t.element_a do |a|
        a.nested_element
      end

      t.element_b
      t.repeated_element_c

      t.repeated_and_nested_element_d do |d|
        d.nested_element
      end

      t.nonexistent_element_e

      t.element_f do |f|
        f.attr :path => '@attr'
      end

      t.element_g :path => '//element_g' do |g|
        g.element_h
      end
    end
    
    attr_accessor :ng_xml
  end

  let(:xml_data) { <<-eos
                   <root>
                     <element_a>
                       <nested_element>value</nested_element>
                       <element_g>1</element_g>
                     </element_a>
                     <element_b>b_value</element_b>
                     <repeated_element_c>c_value1</repeated_element_c>
                     <repeated_element_c>c_value2</repeated_element_c>
                     <repeated_element_c>c_value3</repeated_element_c>
                     <repeated_element_c>c_value4</repeated_element_c>
                     <repeated_and_nested_element_d>
                       <nested_element>value</nested_element>
                       <nested_element>value2</nested_element>
                       <element_g>
                         <element_h>h value</element_h>
                       </element_g>
                     </repeated_and_nested_element_d>
                     <repeated_and_nested_element_d>
                       <element_g>2</element_g>
                       <nested_element>value3</nested_element>
                     </repeated_and_nested_element_d>
                     <element_f attr="attr_value" />
                     </root>
eos
  }

  subject { TestTerminology.from_xml(xml_data) }

  it "should initialize" do
    subject.should be_a_kind_of OM::XML::Document
  end

  it "should have simple accessors" do
    subject.element_b.first.content.should == "b_value"
  end

  it "should have nested accessors" do
    subject.element_a.first.nested_element.first.content.should == "value"
    subject.element_a.nested_element.first.class.should == OM::XML::Document::Term
  end

  it "should have repeated accessors" do
    subject.repeated_element_c.content.should include("c_value1", "c_value2", "c_value3")
  end

  it "should have repeated and nestedaccessors" do
    subject.repeated_and_nested_element_d.nested_element.map { |x| x.content }.should include("value", "value2", "value3")
    subject.repeated_and_nested_element_d.nested_element.first.content.should == "value"
  end

  it "should have attr accessors" do
    subject.element_f.attr.first.content.should == "attr_value"

    subject.element_f.attr.first.content = 'new_attr_value'
    subject.element_f.attr.first.content.should == "new_attr_value"
  end

  it "should have wildcard paths" do
    subject.element_g.length.should == 3
    subject.element_g.element_h.first.content.should == "h value"
  end

  it "should have setters" do
    subject.element_b = "b_value 9876"
    subject.element_b.first.content.should == "b_value 9876"
  end

  it "should be enumerable" do
    subject.element_b.any? { |x| x.content == "b_value" }.should be_true
  end

  it "should do normal method missing on non-terminology items" do
    expect { subject.element_z }.to raise_error NoMethodError
    expect { subject.element_a.element_z }.to raise_error NoMethodError
    expect { subject.element_a.first.element_z }.to raise_error NoMethodError
  end
end

describe "terms" do
  subject { TestTerminology.new }

  it "should" do
    subject.class.terminology.xpath.should be_nil
    subject.class.terminology.element_a.xpath.should == "element_a"
    subject.class.terminology.element_a.nested_element.xpath.should == "element_a/nested_element"
  end
end
