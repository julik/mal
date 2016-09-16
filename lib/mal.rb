module Mal
  VERSION = '0.0.2'
  
  class AnythingT
    def ===(value)
      true
    end
    def inspect
      'Anything()'
    end
  end

  class OnlyT
    def initialize(matchable)
      @matchable = matchable
    end

    def ===(value)
      @matchable === value
    end

    def inspect
      'Only(%s)' % @matchable.inspect
    end
  end

  class NilT < OnlyT
    def inspect; 'Nil()'; end
  end

  class HashT
    def initialize(**required_keys_to_matchers)
      @required_keys_to_matchers = required_keys_to_matchers
    end
  
    def ===(value)
      return false unless value.is_a?(Hash)
      @required_keys_to_matchers.each_pair do |k,value_matcher|
        return false unless value.key? k
        return false unless value_matcher === value[k]
      end
      true
    end

    def inspect
      'HashWith(%s)' % @required_keys_to_matchers.inspect[1..-2]
    end
  end
  
  class HashOfOnlyT < HashT
    def ===(value)
      return false unless super
      @required_keys_to_matchers.keys == value.keys
    end
    
    def inspect
      'HashOf(%s)' % @required_keys_to_matchers.inspect[1..-2]
    end
  end
  
  class ArrayT < OnlyT
    def initialize(matcher_for_each_array_element)
      @matcher_for_each_array_element = matcher_for_each_array_element
    end
  
    def ===(value)
      return false unless Array === value
      return false unless value.any?
      value.each do |value_element|
        return false unless @matcher_for_each_array_element === value_element
      end
      true
    end
  
    def inspect
      'ArrayOf(%s)' % @matcher_for_each_array_element.inspect
    end
  end

  class LengthT < OnlyT
    def initialize(desired_length)
      @desired_length = length
    end
    
    def ===(value)
      return false unless value.respond_to? :length
      @desired_length == value.length
    end
  end

  class MinLengthT < LengthT
    def ===(value)
      return false unless value.respond_to? :length
      @desired_length >= value.length
    end
    def inspect; 'OfAtLeastElements(%d)' % @desired_length; end
  end

  class MaxLengthT < LengthT
    def ===(value)
      return false unless value.respond_to? :length
      @desired_length <= value.length
    end
    def inspect; 'OfAtMostElements(%d)' % @desired_length; end
  end

  class EitherT < OnlyT
    def initialize(*types)
      @types = types
    end
  
    def ===(value)
      @types.any? {|type| type === value }
    end
  
    def inspect
      'Either(%s)' % @types.map{|e| e.inspect }.join(', ')
    end
  end

  class UnionT < OnlyT
    def initialize(*types)
      @types = types
    end
  
    def ===(value)
      @types.all? {|type| type === value}
    end
  
    def inspect
      'Both(%s)' % @types.map{|e| e.inspect }.join(', ')
    end
  end

  class MaybeT < EitherT
    def inspect; 'Maybe(%s)' % @types[1].inspect; end
  end
  
  class BoolT < EitherT
    def initialize; super(TrueClass, FalseClass); end
    def inspect; 'Bool()'; end
  end
  
  private_constant :NilT, :BoolT, :EitherT, :MaybeT, :ArrayT, :HashT, :BoolT, :HashOfOnlyT, :MaxLengthT, :MinLengthT
  
  # Specifies a value that may only ever be `nil` and nothing else
  def Nil()
    NilT.new(NilClass)
  end

  # Specifies a value that is either `true` or `false` (truthy or falsy values do not work)
  def Bool()
    BoolT.new
  end

  # Specifies a value that matches only the given matcher
  def Only(matchable)
    OnlyT.new(matchable)
  end

  # Specifies a value that matches both the given matchers. For instance,
  # can be a matcher for both a String and a Regexp
  def Both(*matchables)
    UnionT.new(*matchables)
  end
  
  # Specifies a value that matches either one of the given speciciers
  def Either(*matchables)
    EitherT.new(*matchables)
  end

  # Specifies a value that is either matching the given typespec, or is nil
  def Maybe(matchable)
    MaybeT.new(NilClass, matchable)
  end

  # Specifies an Array of at least 1 element, where each element matches the
  # typespec for the array element 
  def ArrayOf(typespec_for_array_element)
    ArrayT.new(typespec_for_array_element)
  end

  # Specifies a Hash containing at least the given keys, with values at those
  # keys matching the given matchers. For example, for a Hash having at
  # least the `:name` key with a corresponding value that is a String:
  #   HashOf(name: String)
  # Since the match is non-strict, it will also match a Hash having more keys
  #   HashOf(name: String) === {name: 'John Doe', age: 21} #=> true
  def HashWith(**keys_to_values)
    HashT.new(**keys_to_values)
  end
  
  def OfAtLeastElements(n)
    MinLengthT.new(n)
  end

  def OfAtMostElements(n)
    MaxLengthT.new(n)
  end
  
  # Specifies a Hash containing only the given keys, with values at those
  # keys matching the given matchers. For example, for a Hash having at
  # the `:name` key with a corresponding value that is a String:
  #
  #   HashOfOnly(name: String)
  #
  # Because the match is-strict, it will not match a Hash having additional keys
  #
  #   HashOf(name: String) === {name: 'John Doe', age: 21} #=> false
  def HashOf(**keys_to_values)
    HashOfOnlyT.new(**keys_to_values)
  end
  
  # Just like it says: will match any value given to it
  def Anything()
    AnythingT.new
  end
  
  extend self
end
