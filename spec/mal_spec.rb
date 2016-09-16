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
  end
end
