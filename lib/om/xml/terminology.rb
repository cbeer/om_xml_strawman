module OM::XML
  class Term
    attr_reader :name
    attr_reader :terms
    attr_reader :parent

    def initialize parent, name, *args, &block
      @name = name
      @terms = {}
      @parent = parent

      in_edit_context do
        yield(self) if block_given?
      end
    end

    def in_edit_context &block
      @edit_context = true
      yield
      @edit_context = false
    end

    def xpath
      [self.parent.xpath, name].flatten.compact.join("/")
    end
    
    def method_missing method, *args, &block 
      if @edit_context
        terms[method] = Term.new(self, method, *args, &block)
      else
        return terms[method] if key?(method)
        super
      end
      #terms[method]
    end

    def key? term
      terms.key? term
    end
  end

  class Terminology < Term
    def initialize *args, &block
      @terms = {}
      in_edit_context do
        yield(self) if block_given?
      end
    end

    def xpath
      nil
    end
  end
end
