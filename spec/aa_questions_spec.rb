require 'rspec'
require 'active_support'
require_relative '../lib/aa_questions'

RSpec.describe ModelBase do
  describe '::find_by_id' do
    it 'finds an object by id' do
      expect(User.find_by_id(1)).to be_a(User)
    end
  end

  describe '::all' do

    user = User.find_by_id(1)
    it 'returns all objects in table for given class' do

      expect(User.all).to include(user)
    end
  end
end
