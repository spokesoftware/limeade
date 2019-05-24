
RSpec.describe Limeade::Client do

  describe 'new' do
    subject { described_class.new }

    it 'instantiates the client' do
      expect(subject).to be
    end
  end
end