require_relative 'spec_helper'

describe 'Mal' do
  describe '.typespec' do
    it 'allows shorthand typespecs to be created without module prefixing' do
      matcher = Mal.typespec { Maybe(String) }
      expect(matcher.inspect).to eq('Maybe(String)')
    end
  end
end
