# The module allows you to define simple data structure schemas, and to match your data against
# those schemas. Primary use is for HTTP parameters, JSON-derived datastructures and the like.
#
# Let's start with the basics. Any "typespec" returned by the library responds to `===`. The most
# basic (and all-encompassing) typespec there is is called `Anything()`.
#
#     Anything() === false  #=> true
#     Anything() === true   #=> true
#     Anything() === Module #=> true
#
# A more specific type is an Only(), which is similar to just using a class, module or Regexp (which
# all support ===), but it can be composed with other typespecs.
#
#    Only(/hello/) === 123           #=> false
#    Only(/hello/) === "hello world" #=> true
#
# Interesting things come into play when you use combinations of the typespecs. For example, you want
# to ensure the value referenced by `my_var` is either a Fixnum or a String matching a regular expression.
# For this, you need to create a compound matcher using an `Either()` typespec (disjoint union):
#
#    Either(Fixnum, Both(String, /hello/)) === "hello world"  #=> true
#    Either(Fixnum, Both(String, /hello/)) === 123            #=> true
#    Either(Fixnum, Both(String, /hello/)) === Module         #=> false, since it is neither of
#
# You can also use the `|` operator on most of the typespecs to create these disjoint unions - but
# if you have a matchable object on the left side of the expression you mught have to wrap it in an
# `Only()`:
#
#    Only(Fixnum) | Only(String) #=> Either(Fixnum, String)
#
# Even more entertainment becomes possible when you match deeper structures with nesting - hashes for example.
# There are two methods for those - `HashWith()` and `HashOf`. `HashWith` checks for the presence of the given
# key/value pairs and checks values for matches, but if there are _other_ keys present in the Hash given for
# verification it won't complain. `HashOf()`, in contrast, will ensure there are _only_ the mentioned keys
# in the Hash, and will not match if something else is present.
#
#    HashWith(age: Fixnum) === {age: 12, name: 'Cisco Kid'} #=> true
#    HashOf(age: Fixnum) === {age: 12, name: 'Cisco Kid'} #=> false
#
# Note that it is _entirely_ plausible that you would not want to include Mal into
# your object/class/whatever. For that case, calling methods using their qualified
# module name (`Mal.Some()...`) can become a nuisance. If it does,
# use `Mal.typespec` which is a shortcut to `instance_exec` - but has the convenient
# property of not alerting your style watchers to your use of `instance_exec` :-P
module Mal
  VERSION = '0.0.5'
  
  class AnythingT
    def ===(value)
      true
    end
    def inspect
      'Anything()'
    end
    
    def |(another)
      self
    end
    
    def &(another)
      another # Another is automatically considered more specific, and replaces Anything
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
    
    def |(another)
      if another.is_a?(AnythingT)
        another
      else
        EitherT.new(self, another)
      end
    end
    
    def &(another)
      if another.is_a?(AnythingT)
        self
      else
        UnionT.new(self, another)
      end
    end
  end

  class NilT < OnlyT
    def inspect; 'Nil()'; end
    def |(another); MaybeT.new(another); end
  end

  class HashT < OnlyT
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
  
  class ObjectT < OnlyT
    attr_reader :supported_methods
    def initialize(*supported_methods)
      @supported_methods = supported_methods.map(&:to_sym)
    end
  
    def ===(value)
      @supported_methods.each do |m|
        return false unless value.respond_to?(m)
      end
      true
    end

    def inspect
      'ObjectWith(%s)' % @supported_methods.map(&:inspect).join(', ')
    end
    
    def &(another)
      if another.is_a?(ObjectT)
        methods_of_both = (@supported_methods + another.supported_methods).uniq
        ObjectT.new(*methods_of_both)
      end
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

  class HashPermittingT < HashT
    def ===(value)
      return false unless super
      permitted = Set.new(@required_keys_to_matchers.keys)
      present = Set.new(value.keys)
      present.subset?(permitted)
    end
    
    def inspect
      'HashPermitting(%s)' % @required_keys_to_matchers.inspect[1..-2]
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
    
    def inspect; 'OfElements(%d)' % @desired_length; end
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
    attr_reader :types
    def initialize(*types)
      @types = types
    end
  
    def ===(value)
      @types.any? {|type| type === value }
    end
  
    def inspect
      'Either(%s)' % @types.map{|e| e.inspect }.join(', ')
    end
    
    def |(another)
      types_matched = if another.is_a?(EitherT)
        (@types + another.types).uniq
      else
        (@types + [another]).uniq
      end
      EitherT.new(*types_matched)
    end
  end

  class UnionT < OnlyT
    attr_reader :types
    def initialize(*types)
      @types = types
    end
  
    def ===(value)
      @types.all? {|type| type === value}
    end
  
    def inspect
      'Both(%s)' % @types.map{|e| e.inspect }.join(', ')
    end
    
    def &(another)
      if another.is_a?(UnionT)
        unique_types = (@types + another.types).uniq
        return UnionT.new(*unique_types)
      end
      super
    end
  end

  class MaybeT < EitherT
    def initialize(matchable); super(NilClass, matchable); end
    def inspect; 'Maybe(%s)' % @types[1].inspect; end
  end
  
  class BoolT < EitherT
    def initialize; super(TrueClass, FalseClass); end
    def inspect; 'Bool()'; end
    def |(another); EitherT.new(self, another); end
  end
  
  class ValueT < OnlyT
    def ===(value)
      @matchable == value
    end
    def inspect; 'Value(%s)' % @matchable.inspect; end
  end
  
  class SatisfyingT < OnlyT
    def initialize(&blk)
      super(blk.to_proc) # Use an OnlyT since Proc objects support ===
    end
    def inspect; 'Satisfying(&blk)'; end
  end

  class IncludingT < ValueT
    def ===(value)
      @matchable.include?(value)
    end
    def inspect; 'IncludedIn(%s)' % @matchable.inspect; end
  end
  
  class CoveringT < ValueT
    def ===(value)
      @matchable.cover?(value)
    end
    def inspect; 'CoveredBy(%s)' % @matchable.inspect; end
  end

  typespec_consts = self.constants.grep(/[a-z]T$/)
  private_constant *typespec_consts

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
    MaybeT.new(matchable)
  end

  # Specifies an Array of at least 1 element, where each element matches the
  # typespec for the array element 
  def ArrayOf(typespec_for_array_element)
    ArrayT.new(typespec_for_array_element)
  end

  # Specifies a Hash containing at least the given keys, with values at those
  # keys matching the given matchers. For example, for a Hash having at
  # least the `:name` key with a corresponding value that is a String:
  #
  #   HashWith(name: String)
  #
  # Since the match is non-strict, it will also match a Hash having more keys
  #
  #   HashWith(name: String) === {name: 'John Doe', age: 21} #=> true
  def HashWith(**keys_to_values)
    HashT.new(**keys_to_values)
  end

  # Specifies an object responding to certain methods
  #
  #   ObjectWith(:downcase) === "foo" #=> true
  def ObjectWith(*properties)
    ObjectT.new(*properties)
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
  
  # Specifies a Hash containing the given keys/values or their subset,
  # will also match an empty Hash. Will _not_ match a Hash having extra
  # keys.
  def HashPermitting(**keys_to_values)
    HashPermittingT.new(**keys_to_values)
  end
  
  # Just like it says: will match any value given to it
  def Anything()
    AnythingT.new
  end
  
  # Matches the contained value exactly using the == operator. Will work well
  # where exact matches are desired, i.e. for strings, numbers and native language
  # types.
  def Value(value)
    ValueT.new(value)
  end
  
  # Matches the given value if the passed block/Proc returns true when called with that value
  #   Satisfying {|x| x > 10 } === 11 #=> true
  def Satisfying(&blk)
    SatisfyingT.new(&blk)
  end
  
  def CoveredBy(range)
    CoveringT.new(range)
  end

  def IncludedIn(*values)
    IncludingT.new(values)
  end
  
  # A shortcut for `instance_exec`, for defining types using shorthand method names
  # from outside the module:
  #
  #    Mal.typespec { Either(Value(1), Value(2)) }
  def self.typespec(&blk)
    instance_exec(&blk)
  end
  
  extend self
end
