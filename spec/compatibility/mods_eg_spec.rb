require 'spec_helper'

describe "an example of xpath-y stuff, also using :proxy and :ref and namespaces" do

  describe "a contrived example" do
    before(:all) do
      class XpathyStuffTerminology
        include OM::XML::Document

        set_terminology do |t|
          t.resource do |r|
            r.file do |f|
              f.location
              f.filename
              f.format
            end
          end
          t.content(:ref=>[:resource, :file], :path=>'resource/file[location="content"]')
          t.html(:ref=>[:resource, :file], :path=>'resource/file[location="html"]')
        end
      end
    end

    subject do
      XpathyStuffTerminology.from_xml <<-EOF
<contentMetadata>
   <resource type="file" id="BU3A5" objectId="val2">
    <file id="BURCH1" format="BINARY">
      <location>content</location>
    </file>
    <file id="BURCH1.html" format="HTML">
      <location>html</location>
    </file>
  </resource>
</contentMetadata>

      EOF
    end

    it "should work" do
      subject.should be_a_kind_of(OM::XML::Document)
    end

    it "should" do
      subject.resource.file.location.content.should include('content', 'html')
    end

    it "should have a content term" do
      subject.content.length.should == 1
      subject.content.location.first.content.should =~ /content/
    end

    it "should have an html term" do
      subject.html.length.should == 1
      subject.html.location.first.content.should =~ /html/
    end


  end

  describe "an example from MODS" do
    before(:all) do
      class ModsXpathyStuffTerminology 
        include OM::XML::Document

        set_terminology do |t|
          t.person do |p|
            p.given(:path=>"namePart[@type='given']")
            p.family(:path=>"namePart[@type='family']")
            p.role do |r|
              r.text(:path=>"roleTerm[@type='text']")
              r.code(:path=>"roleTerm[@type='code']")
            end
          end
          t.author(:ref=>:person, :path=>'name[./role/roleTerm="aut"]')
          t.advisor(:ref=>:person, :path=>'name[./role/roleTerm="ths"]')
        end
      end
    end

    subject do
      ModsXpathyStuffTerminology.from_xml <<-EOF
    <mods>
     <name type="personal">
         <namePart type="given">Mary</namePart>
         <namePart type="family">Pickral</namePart>
         <affiliation>University of Virginia</affiliation>
         <namePart>mpc3c</namePart>
         <affiliation>University of Virginia Library</affiliation>
         <role>
             <roleTerm authority="marcrelator" type="code">aut</roleTerm>
             <roleTerm authority="marcrelator" type="text">author</roleTerm>
         </role>
     </name>
    <name type="personal">
      <namePart>der5y</namePart>
      <namePart type="given">David</namePart>
      <namePart type="family">Jones</namePart>
      <affiliation>University of Virginia</affiliation>
      <affiliation>Architectural History Dept.</affiliation>
      <role>
           <roleTerm authority="marcrelator" type="code">ths</roleTerm>
           <roleTerm authority="marcrelator" type="text">advisor</roleTerm>
      </role>
    </name>
  </mods>
      EOF
    end

    it "should have the terms :author_given and :author_family to get the author name" do
      subject.author.given.content.should include("Mary")
      subject.author.family.content.should include("Pickral")
    end

    it "should have the terms :advisor_given and :advisor_family to get the advisor name" do
      subject.advisor.given.content.should include("David")
      subject.advisor.family.content.should include("Jones")
    end

  end
end


