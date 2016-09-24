require_relative 'spec_helper'

describe 'Mal' do
  include Mal
  
  def expect_match_of(typespec, value)
    match_v = typespec === value
    expect(match_v).to eq(true), "Expected #{value.inspect} to match #{typespec.inspect}"
  end

  def expect_no_match_of(typespec, value)
    match_v = typespec === value
    expect(match_v).to eq(false), "Expected #{value.inspect} not to match #{typespec.inspect}"
  end

  describe 'Anything()' do
    it 'provides a good inspect' do
      expect(Anything().inspect).to eq('Anything()')
    end
    
    it 'matches anything' do
      expect_match_of(Anything(), 0)
      expect_match_of(Anything(), self)
      expect_match_of(Anything(), true)
      expect_match_of(Anything(), nil)
    end
    
    it 'ORs to itself' do
      m = Anything() | Bool()
      expect(m.inspect).to eq('Anything()')
    end

    it 'ANDs to the right operand' do
      m = Anything() & Bool()
      expect(m.inspect).to eq('Bool()')
    end
  end
  
  describe 'Nil()' do
    it 'provides a good inspect' do
      expect(Nil().inspect).to eq('Nil()')
    end
    
    it 'matches nil only' do
      expect_match_of(Nil(), nil)
      expect_no_match_of(Nil(), 0)
      expect_no_match_of(Nil(), Object.new)
      expect_no_match_of(Nil(), self)
    end
    
    it 'ORs to a Maybe of Nil() and Bool()' do
      m = Nil() | Bool()
      expect(m.inspect).to eq('Maybe(Bool())')
      expect_match_of(m, nil)
      expect_match_of(m, true)
      expect_match_of(m, false)
      expect_no_match_of(m, 0)
    end
    
    it 'ANDs to a Both()' do
      m = Nil() & Bool()
      expect(m.inspect).to eq('Both(Nil(), Bool())')
    end
  end

  describe 'Bool()' do
    it 'provides a good inspect' do
      expect(Bool().inspect).to eq('Bool()')
    end
    
    it 'matches only true and false' do
      expect_match_of(Bool(), true)
      expect_match_of(Bool(), false)
      expect_no_match_of(Bool(), nil)
      expect_no_match_of(Bool(), self)
      expect_no_match_of(Bool(), 'hello world')
      expect_no_match_of(Bool(), 123)
    end
    
    it 'ORs to a an Either()' do
      m = Bool() | Fixnum
      expect(m.inspect).to eq('Either(Bool(), Fixnum)')
      expect_match_of(m, true)
      expect_match_of(m, false)
      expect_match_of(m, 12)
      expect_no_match_of(m, 'hello world')
      expect_no_match_of(m, [])
    end
    
    it 'ANDs to a Both()' do
      m = Bool() & TrueClass
      expect(m.inspect).to eq('Both(Bool(), TrueClass)')
    end
  end
  
  describe 'Either()' do
    it 'provides a good inspect' do
      expect(Either(String, Hash).inspect).to eq('Either(String, Hash)')
    end

    it 'matches either of given' do
      m = Either(String, TrueClass)
      expect_match_of(m, 'hello world')
      expect_match_of(m, true)
      expect_no_match_of(m, false)
      expect_no_match_of(m, nil)
      expect_no_match_of(m, self)
    end
    
    it 'ORs to a union Either()' do
      m = Either(Fixnum, TrueClass) | Anything()
      expect(m.inspect).to eq('Either(Fixnum, TrueClass, Anything())')
      expect_match_of(m, true)
      expect_match_of(m, false)
      expect_match_of(m, 12)
      expect_match_of(m, 'hello world')
      expect_match_of(m, [])
    end
    
    it 'ORs to a union of two Either() types' do
      m = Either(Fixnum, TrueClass) | Either(Fixnum, FalseClass)
      expect(m.inspect).to eq('Either(Fixnum, TrueClass, FalseClass)')
      expect_match_of(m, true)
      expect_match_of(m, false)
      expect_match_of(m, 12)
      expect_no_match_of(m, 'hello world')
      expect_no_match_of(m, [])
    end
    
    it 'ANDs to a Both()' do
      m = Either(Fixnum, TrueClass) & TrueClass
      expect(m.inspect).to eq('Both(Either(Fixnum, TrueClass), TrueClass)')
    end
  end

  describe 'Maybe()' do
    it 'provides a good inspect' do
      expect(Maybe(String).inspect).to eq('Maybe(String)')
    end

    it 'matches a nil or a given type' do
      m = Maybe(String)
      expect_match_of(m, nil)
      expect_match_of(m, 'foo')
      expect_no_match_of(m, false)
      expect_no_match_of(m, self)
    end
    
    it 'ORs to an Either()' do
      m = Maybe(String) | Fixnum
      expect(m.inspect).to eq('Either(NilClass, String, Fixnum)')
    end
    
    it 'ANDs to a Both()' do
      m = Maybe(String) & TrueClass
      expect(m.inspect).to eq('Both(Maybe(String), TrueClass)')
    end
  end
  
  describe 'ArrayOf()' do
    it 'provides a good inspect' do
      expect(ArrayOf(Maybe(Fixnum)).inspect).to eq('ArrayOf(Maybe(Fixnum))')
    end
    
    it 'does not match objects of other types' do
      expect_no_match_of(ArrayOf(TrueClass), nil)
      expect_no_match_of(ArrayOf(TrueClass), false)
      expect_no_match_of(ArrayOf(TrueClass), self)
      expect_no_match_of(ArrayOf(TrueClass), 123)
    end
    
    it 'does not match an empty Array' do
      expect_no_match_of(ArrayOf(TrueClass), [])
    end
    
    it 'matches an Array containing objects of matching types' do
      m = ArrayOf(Fixnum)
      expect_no_match_of(m, [true, false, 1, 'foo'])
      expect_match_of(m, [1, 78451, 546])
    end
    
    it 'matches an Array of elements parametrized via union types' do
      m = ArrayOf(Either(Fixnum, Bool()))
      expect_no_match_of(m, [true, false, 1, 'foo'])
      expect_match_of(m, [true, false, 1])
    end
    
    it 'ORs to an Either()' do
      m = ArrayOf(String) | ArrayOf(Fixnum)
      expect(m.inspect).to eq('Either(ArrayOf(String), ArrayOf(Fixnum))')
      expect_match_of(m, ['a', 'b', 'c'])
      expect_match_of(m, [1, 2, 3])
      expect_no_match_of(m, ['a', 2, 3])
    end
    
    it 'ANDs to a Both()' do
      m = ArrayOf(Maybe(String)) & ArrayOf(String)
      expect(m.inspect).to eq('Both(ArrayOf(Maybe(String)), ArrayOf(String))')
    end
  end

  describe 'Both()' do
    it 'provides a good inspect' do
      m = Both(String, /abc/)
      expect(m.inspect).to eq("Both(String, /abc/)")
    end

    it 'provides matching against all the elements' do
      m = Both(String, /abc/)
      expect_match_of(m, 'this is an abc string')
      expect_no_match_of(m, 'this is a string that does match the second parameter')
    end
    
    it 'ORs to an Either()' do
      m = Both(String, /hello/) | Fixnum
      expect(m.inspect).to eq('Either(Both(String, /hello/), Fixnum)')
      expect_match_of(m, 'hello')
      expect_no_match_of(m, 'goodbye')
      expect_match_of(m, 123)
    end

    it 'ANDs to a Both()' do
      m = Both(String, /hello/) & Maybe(Fixnum)
      expect(m.inspect).to eq('Both(Both(String, /hello/), Maybe(Fixnum))')
      expect_no_match_of(m, 'hello')
      expect_no_match_of(m, 'goodbye')
      expect_no_match_of(m, 123)
    end

    it 'ANDs to a flattened Both() if the right hand operand is also a Both' do
      m = Both(String, /hello/) & Both(String, /he/)
      expect(m.inspect).to eq('Both(String, /hello/, /he/)')
      expect_match_of(m, 'hello')
      expect_no_match_of(m, 'goodbye')
      expect_no_match_of(m, 123)
    end
  end

  describe 'HashWith()' do
    it 'provides a good inspect' do
      m = HashWith(foo: Maybe(Fixnum))
      expect(m.inspect).to eq("HashWith(:foo=>Maybe(Fixnum))")
    end
    
    it 'does not match other types' do
      m = HashWith(foo: Symbol)
      expect_no_match_of(m, nil)
      expect_no_match_of(m, [])
      expect_no_match_of(m, self)
    end
    
    it 'does match an empty Hash when asked to' do
      m = HashWith({})
      expect_match_of(m, {})
    end
    
    it 'does not match a Hash whose value does not satisfy the matcher' do
      m = HashWith(some_key: Nil())
      expect_no_match_of(m, {some_key: true})
    end
    
    it 'does match a Hash whose keys/values do satisfy the matcher' do
      m = HashWith(some_key: Maybe(String))
      expect_match_of(m, {some_key: nil})
      expect_match_of(m, {some_key: 'hello world'})
    end

    it 'does match a Hash that has more keys than requested' do
      m = HashWith(name: String)
      expect_match_of(m, {name: 'John Doe', age: 21})
    end
    
    it 'ORs to an Either()' do
      m = HashWith(name: String) | HashWith(first_name: String, last_name: String)
      expect(m.inspect).to eq('Either(HashWith(:name=>String), HashWith(:first_name=>String, :last_name=>String))')
      expect_match_of(m, {name: 'Jane'})
      expect_match_of(m, {first_name: 'Jane', last_name: 'Doe'})
      expect_match_of(m, {name: 'Jane', first_name: 'Jane', last_name: 'Doe'})
    end
    
    it 'ANDs to a Both' do
      m = Both(HashWith(name: Anything()), HashWith(age: Anything()))
      expect(m.inspect).to eq('Both(HashWith(:name=>Anything()), HashWith(:age=>Anything()))')
      expect_match_of(m, {name: nil, age: 12})
      expect_no_match_of(m, {name: 'Jane'})
      expect_no_match_of(m, {age: 21})
    end
  end

  describe 'HashPermitting()' do
    it 'provides a good inspect' do
      m = HashPermitting(foo: Maybe(Fixnum))
      expect(m.inspect).to eq("HashPermitting(:foo=>Maybe(Fixnum))")
    end
    
    it 'does not match other types' do
      m = HashPermitting(foo: Symbol)
      expect_no_match_of(m, nil)
      expect_no_match_of(m, [])
      expect_no_match_of(m, self)
    end
    
    it 'does match an empty Hash when asked to' do
      m = HashPermitting({})
      expect_match_of(m, {})
    end
    
    it 'does not match a Hash whose value does not satisfy the matcher' do
      m = HashPermitting(some_key: Nil())
      expect_no_match_of(m, {some_key: true})
    end
    
    it 'does match a Hash whose keys/values do satisfy the matcher' do
      m = HashPermitting(some_key: Maybe(String))
      expect_match_of(m, {some_key: nil})
      expect_match_of(m, {some_key: 'hello world'})
    end

    it 'does not match a Hash that has more keys than requested' do
      m = HashPermitting(name: String)
      expect_no_match_of(m, {name: 'John Doe', age: 21})
    end
    
    it 'ORs to an Either()' do
      m = HashPermitting(name: String) | HashPermitting(first_name: String, last_name: String)
      expect(m.inspect).to eq('Either(HashPermitting(:name=>String), HashPermitting(:first_name=>String, :last_name=>String))')
      expect_match_of(m, {name: 'Jane'})
      expect_match_of(m, {first_name: 'Jane', last_name: 'Doe'})
      expect_no_match_of(m, {name: 'Jane', first_name: 'Jane', last_name: 'Doe'})
    end
    
    it 'ANDs to a Both' do
      m = Both(HashPermitting(name: Anything()), HashPermitting(name: Anything(), age: Anything()))
      expect(m.inspect).to eq('Both(HashPermitting(:name=>Anything()), HashPermitting(:name=>Anything(), :age=>Anything()))')
      expect_no_match_of(m, {name: nil, age: 12})
      expect_no_match_of(m, {name: 'Jane'})
      expect_no_match_of(m, {age: 21})
    end
  end

  describe 'HashOf()' do
    it 'provides a good inspect' do
      m = HashOf(foo: Maybe(Fixnum))
      expect(m.inspect).to eq("HashOf(:foo=>Maybe(Fixnum))")
    end
    
    it 'does not match other types' do
      m = HashOf(foo: Symbol)
      expect_no_match_of(m, nil)
      expect_no_match_of(m, [])
      expect_no_match_of(m, self)
    end
    
    it 'does match an empty Hash when asked to' do
      m = HashOf({})
      expect_match_of(m, {})
    end
    
    it 'does not match a Hash whose value does not satisfy the matcher' do
      m = HashOf(some_key: Nil())
      expect_no_match_of(m, {some_key: true})
    end
    
    it 'does match a Hash whose keys/values do satisfy the matcher' do
      m = HashOf(some_key: Maybe(String))
      expect_match_of(m, {some_key: nil})
      expect_match_of(m, {some_key: 'hello world'})
    end

    it 'does not match a Hash that has more keys than requested' do
      m = HashOf(name: String)
      expect_no_match_of(m, {name: 'John Doe', age: 21})
    end
    
    it 'ORs to an Either()' do
      m = HashOf(name: String) | HashOf(first_name: String, last_name: String)
      expect(m.inspect).to eq('Either(HashOf(:name=>String), HashOf(:first_name=>String, :last_name=>String))')
      expect_match_of(m, {name: 'Jane'})
      expect_match_of(m, {first_name: 'Jane', last_name: 'Doe'})
      expect_no_match_of(m, {name: 'Jane', first_name: 'Jane', last_name: 'Doe'})
    end
  end
  
  describe 'HashOf with complex nested matchers' do
    it 'matches the User response' do
      m = Mal::HashWith(
        user: Mal::HashWith(
          active_subscription: Mal::Bool(),
          profile_picture_url: Mal::Maybe(String),
          full_name: String,
          id: Integer
        )
      )
      
      expect_match_of(m, {user: {
        id: 123, 
        active_subscription: true,
        profile_picture_url: 'http://url.com',
        full_name: 'John Doe',
      }})
      
      expect_match_of(m, {user: {
        id: 123, 
        interests: ['Fishing', 'Hiking'],
        active_subscription: true,
        profile_picture_url: 'http://url.com',
        full_name: 'John Doe',
      }})
      
      expect_no_match_of(m, {user: {
        # skip the "id" field and let the matcher fail
        interests: ['Fishing', 'Hiking'],
        active_subscription: true,
        profile_picture_url: 'http://url.com',
        full_name: 'John Doe',
      }})
    end
  end
  
  describe 'Anything()' do
    it 'has a reasonable inspect' do
      expect(Anything().inspect).to eq('Anything()')
    end
    
    it 'matches truly anything' do
      expect_match_of(Anything(), {})
      expect_match_of(Anything(), self)
      expect_match_of(Anything(), true)
      expect_match_of(Anything(), false)
    end
    
    it 'ANDs to the right hand operand' do
      m = Anything() & Bool()
      expect(m.inspect).to eq('Bool()')
    end
  end

  describe 'ObjectWith()' do
    it 'has a reasonable inspect' do
      expect(ObjectWith(:upcase, :downcase).inspect).to eq('ObjectWith(:upcase, :downcase)')
    end
    
    it 'matches only objects that respond to the methods defined' do
      m = ObjectWith(:upcase, :downcase)
      only_downcase = Struct.new(:downcase).new('nope')
      only_upcase = Struct.new(:upcase).new('nope')
      both = Struct.new(:upcase, :downcase).new('A', 'a')
      
      expect_match_of(m, 'foo')
      expect_match_of(m, both)
      expect_no_match_of(m, only_downcase)
      expect_no_match_of(m, only_upcase)
    end
    
    it 'ORs to a Both' do
      m = ObjectWith(:upcase) | Nil()
      
      expect(m.inspect).to eq('Either(ObjectWith(:upcase), Nil())')
    end
    
    it 'ANDs to a single ObjectWith' do
      m = ObjectWith(:upcase) & ObjectWith(:downcase)
      
      expect(m.inspect).to eq('ObjectWith(:upcase, :downcase)')
      
      only_downcase = Struct.new(:downcase).new('nope')
      only_upcase = Struct.new(:upcase).new('nope')
      both = Struct.new(:upcase, :downcase).new('A', 'a')
      
      expect_match_of(m, 'foo')
      expect_match_of(m, both)
      expect_no_match_of(m, only_downcase)
      expect_no_match_of(m, only_upcase)
    end
  end
  
  describe 'Value()' do
    it 'provides a good inspect' do
      expect(Value('ohai').inspect).to eq('Value("ohai")')
    end
    
    it 'matches only the exact value given' do
      expect_match_of(Value(8), 8)
      expect_no_match_of(Value(8), 4)
      expect_no_match_of(Value(8), {})
      expect_no_match_of(Value(:ohai), {})
    end
    
    it 'ORs to an Either' do
      m = Value(7) | Value(5)
      expect(m.inspect).to eq('Either(Value(7), Value(5))')
    end

    it 'ANDs to the right operand' do
      m = Value(10) & Value(2)
      expect(m.inspect).to eq('Both(Value(10), Value(2))')
    end
  end

  describe 'CoveredBy()' do
    it 'provides a good inspect' do
      expect(CoveredBy(1..4).inspect).to eq('CoveredBy(1..4)')
    end

    it 'matches values covered by the Range' do
      m = CoveredBy(1..4)
      expect_match_of(m, 1)
      expect_match_of(m, 2)
      expect_match_of(m, 3)
      expect_match_of(m, 4)

      expect_no_match_of(m, 0)
      expect_no_match_of(m, 5)
      expect_no_match_of(m, 'Ohai')
      expect_no_match_of(m, nil)
    end
  end
end
