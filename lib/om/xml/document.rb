require 'active_support/concern'
require 'active_support/core_ext/module'
require 'nokogiri'

module OM::XML::Document
  extend ActiveSupport::Concern

  included do
    class <<self
      attr_reader :terminology
      attr_accessor :ng_xml
    end
  end

  module ClassMethods
    def from_xml data
      k = self.new
      k.load_data data
      k
    end

    def set_terminology &block
      remove_terminology_methods
      @terminology = OM::XML::Terminology.new &block
      build_terminology_methods
    end

    def remove_terminology_methods
      return unless @term_class

      @term_class.instance_methods.each do |x|
        if m = instance_method(x) and m.owner == @term_class
          undef_method m
        end
      end
    end

    def build_terminology_methods 
      @term_class = self.const_set("Terminology", Module.new)

      terminology.terms.each do |key, term|
        @term_class.send(:define_method, term.name) do
          find_term(term.name)
        end

        @term_class.send(:define_method, :"#{term.name}=") do |value|
          find_term(term.name).first.content = value
        end
      end

      include @term_class
    end
  end

  def find_term term
    TermSet.new self, nil, term
  end

  def load_data data
    @ng_xml = Nokogiri::XML data
  end


  class TermSet
    include Enumerable
    attr_reader :document
    attr_reader :parent
    attr_reader :term

    def initialize document, parent, term
      @document = document
      @parent = parent
      @term = term
    end

    delegate :ng_xml, :to => :document

    def terminology
      if parent
        parent.terminology
      else
        document.class.terminology
      end.send(term)
    end

    def xpath
      terminology.xpath
    end

    def nodes
      ng_xml.root.xpath(xpath).map { |node| Term.new document, self, term, node }
    end

    def content
      nodes.map { |x| x.content }
    end

    
    def method_missing name, *args, &block
      if terminology.key? name
        nodes.map { |x| x.send(name, *args, &block).nodes }.flatten
      else
        super
      end
    end

    delegate :each, :to => :nodes
  end

  class Term
    attr_reader :document
    attr_reader :parent
    attr_reader :term
    attr_reader :node

    def initialize document, parent, term, node
      @document = document
      @parent = parent
      @term = term
      @node = node
    end

    delegate :content, :content=, :to => :node
    #delegate :to_s, :to => :content

    def method_missing name, *args, &block
      if terminology.key? name
        TermSet.new parent.document, self, name
      else
        super
      end
    end

    def terminology
      parent.terminology
    end

  end
end
