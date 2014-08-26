require_relative '../server'
require 'rspec'
require 'rack/test'

describe 'Server' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  context 'correctness' do
    it 'works for the example data in the requirements' do
      post '/stock_prices?symbol=OMGSTOCK', <<-END.sub(/\s+/, '')
        1462558650,2024.26
        1462645050,2022.18
        1462731450,2020.44
        1462817850,2001.90
        1462904250,2033.34
        1462990650,2060.54
        1463077050,2064.16
        1463163450,2068.08
      END
      expect(last_response.body).to eq('OMGSTOCK,1462817850,1463163450')
    end

    it 'works for monotonically increasing stock' do
      post '/stock_prices?symbol=GREATSTOCK', <<-END.sub(/\s+/, '')
        1,3
        2,4
      END
      expect(last_response.body).to eq('GREATSTOCK,1,2')
    end

    it 'works for monotonically decreasing stock' do
      post '/stock_prices?symbol=OMGSTOCK', <<-END.sub(/\s+/, '')
        1,4
        2,3
      END
      expect(last_response.body).to eq('OMGSTOCK,1,1')
    end

    it 'returns the first minimum if appropriate' do
      post '/stock_prices?symbol=OMGSTOCK', <<-END.sub(/\s+/, '')
        1,12
        2 , 11 
        3,13
        4,10
        5,11
      END
      expect(last_response.body).to eq('OMGSTOCK,2,3')
    end

    it 'returns the second minimum if appropriate' do
      post '/stock_prices?symbol=OMGSTOCK', <<-END.sub(/\s+/, '')
        1,12
        2,11
        3,13
        4,10
        5,13
      END
      expect(last_response.body).to eq('OMGSTOCK,4,5')
    end

    it 'returns the first maximum if appropriate' do
      post '/stock_prices?symbol=OMGSTOCK', <<-END.sub(/\s+/, '')
        1,10
        2,12
        3,10
        4,11
      END
      expect(last_response.body).to eq('OMGSTOCK,1,2')
    end

    it 'returns the second maximum if appropriate' do
      post '/stock_prices?symbol=OMGSTOCK', <<-END.sub(/\s+/, '')
        1,10
        2,12
        3,10
        4,13
      END
      expect(last_response.body).to eq('OMGSTOCK,1,4')
    end

    it 'handles the penny stock case correctly' do
      post '/stock_prices?symbol=OMGSTOCK', <<-END.sub(/\s+/, '')
        1,10
        2,30
        3,1
        4,9
      END
      expect(last_response.body).to eq('OMGSTOCK,3,4')
    end
  end

  context 'with bad input' do
    it 'accepts a single price point' do
      post '/stock_prices?symbol=OMGSTOCK', <<-END.sub(/\s+/, '')
        1,4
      END
      expect(last_response.body).to eq('OMGSTOCK,1,1')
    end

    it 'errors on zero price points' do
      post '/stock_prices?symbol=OMGSTOCK', ''
      expect(last_response).to be_bad_request
      expect(last_response.body).to include('need at least one point')
    end

    it 'errors on malformed price points' do
      post '/stock_prices?symbol=OMGSTOCK', 'bad-point'
      expect(last_response).to be_bad_request
      expect(last_response.body).to include('not a valid price point')
    end

    it 'errors on unordered price points' do
      post '/stock_prices?symbol=GREATSTOCK', <<-END.sub(/\s+/, '')
        1,2
        1,3
      END
      expect(last_response).to be_bad_request
      expect(last_response.body).to include('price point not in chronological order')
    end

    it 'errors on missing symbol' do
      post '/stock_prices'
      expect(last_response).to be_bad_request
      expect(last_response.body).to include('invalid stock symbol')
    end

    it 'errors on invalid symbol' do
      post '/stock_prices?symbol=a,b'
      expect(last_response).to be_bad_request
      expect(last_response.body).to include('invalid stock symbol')
    end

    it 'errors if price is zero' do
      post '/stock_prices?symbol=OMGSTOCK', <<-END.sub(/\s+/, '')
        1,0
      END
      expect(last_response).to be_bad_request
      expect(last_response.body).to include('price must not be zero')
    end
  end
end