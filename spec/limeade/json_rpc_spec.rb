require 'spec_helper'
require 'json'

RSpec.describe Limeade::JSON_RPC do

  let(:instance) { described_class.new(endpoint) }
  let(:endpoint) { 'https://example.limequery.com/admin/remotecontrol' }

  describe 'new' do

    context 'without optional retry_options' do
      subject { instance }

      context 'with a valid URI' do
        let(:endpoint) { 'https://example.limequery.com/admin/remotecontrol' }

        it 'instantiates the class and stores the validated URI' do
          expect(subject).to be_a(described_class)
          expect(subject.instance_variable_get(:@uri)).to eq(endpoint)
        end

        it 'defaults retry_options with an empty Hash' do
          expect(subject.instance_variable_get(:@retry_options)).to eq({})
        end
      end

      context 'with an invalid URI' do
        let(:endpoint) { '%invalid' }
        it 'raises an exception' do
          expect{subject}.to raise_error(URI::InvalidURIError)
        end
      end

    end

    context 'with optional retry_options' do
      subject { described_class.new(endpoint, retry_options) }
      let(:endpoint) { 'https://example.limequery.com/admin/remotecontrol' }

      context 'set to nil' do
        let(:retry_options) { nil }
        it 'uses the default' do
          expect(subject.instance_variable_get(:@retry_options)).to eq({})
        end
      end
    end
  end

  describe 'invoke' do
    subject { instance.invoke(method, *params) }
    let(:method) { 'fetch' }
    let(:params) { [123] }
    let(:result) { 'Hello World!' }
    let(:request_id) { 1 }

    it 'posts to the API with the proper parameters' do
      # First, mock the call to the API
      expect(instance.instance_eval {connection}).to receive(:post) do |*args|
        # Confirm that the parameters are properly sent.
        expect(args[0]).to eq(endpoint)
        data = JSON.parse(args[1])
        expect(data['jsonrpc']).to eq(described_class::JSON_RPC_VERSION)
        expect(data['method']).to eq(method)
        expect(data['params']).to eq(params)
        expect(data['id']).to eq(request_id)
      end.and_return(Faraday::Response.new(body: {'id'=>request_id, 'result'=>result, 'error'=>nil}.to_json))
      # And mock the request id for consistency
      expect(instance).to receive(:make_id).and_return(request_id)

      # Confirm that the result is properly extracted from the response.
      expect(subject).to eq(result)
    end
  end

  describe 'verify_response' do
    subject do
      arg = response
      instance.instance_eval {verify_response(arg)}
    end

    context 'with a nil response' do
      let(:response) { nil }
      it 'raises InvalidResponseError with descriptive message' do
        expect{subject}.to raise_error(Limeade::InvalidResponseError, 'Response is nil')
      end
    end

    context 'with a nil response body' do
      let(:response) { Faraday::Response.new }
      it 'raises InvalidResponseError with descriptive message' do
        expect{subject}.to raise_error(Limeade::InvalidResponseError, 'Response body is nil')
      end
    end

    context 'with an empty response body' do
      let(:response) { Faraday::Response.new(body: {}) }
      it 'raises InvalidResponseError with descriptive message' do
        expect{subject}.to raise_error(Limeade::InvalidResponseError, 'Response body is empty')
      end
    end

    context 'with a non-empty response body' do
      let(:response) { Faraday::Response.new(body: {'foo'=>'bar'}) }
      it 'does not raise an exception' do
        expect{subject}.not_to raise_error
      end
    end
  end

  describe 'payload_from' do
    subject do
      arg = response
      instance.instance_eval {payload_from(arg)}
    end

    context 'with valid JSON in the response body' do
      let(:response) { Faraday::Response.new(body: '{ foo: "bar" }') }
      it 'raises InvalidJSON with descriptive message' do
        expect{subject}.to raise_error(Limeade::InvalidJSONError, /unexpected token/)
      end
    end

    context 'with invalid JSON in the response body' do
      let(:response) { Faraday::Response.new(body: '{ "foo": "bar" }') }
      it 'returns the parsed response body' do
        expect(subject).to eq({ 'foo' => 'bar' })
      end
    end
  end

  describe 'verify_payload' do
    subject do
      args = [payload, request_id]
      instance.instance_eval {verify_payload(*args)}
    end

    let(:request_id) { 1 }

    context 'when the payload is not a Hash' do
      let(:payload) { [] }
      it 'raises InvalidResponseError with descriptive message' do
        expect{subject}.to raise_error(Limeade::InvalidResponseError, 'Response body is not a Hash')
      end
    end

    context 'with the expected payload bits' do
      let(:valid_payload) { {'id'=>request_id, 'result'=>'Hello World!', 'error'=>nil} }
      let(:payload) { valid_payload }

      it 'returns without raising an exception' do
        expect{subject}.not_to raise_error
      end

      context 'except without an id entry' do
        let(:payload) { valid_payload.tap {|p| p.delete('id')} }
        it 'raises InvalidResponseError with descriptive message' do
          expect{subject}.to raise_error(Limeade::InvalidResponseError, 'Response body is missing the id')
        end
      end

      context 'except without an unmatched id' do
        let(:payload) { valid_payload.merge('id' => 2)}
        it 'raises InvalidResponseError with descriptive message' do
          expect{subject}.to raise_error(Limeade::InvalidResponseError, 'Response id (2) does not match request id (1)')
        end
      end

      context 'except without a result entry' do
        let(:payload) { valid_payload.tap {|p| p.delete('result')} }
        it 'raises InvalidResponseError with descriptive message' do
          expect{subject}.to raise_error(Limeade::InvalidResponseError, 'Response body must have a result and an error')
        end
      end

      context 'except without an error entry' do
        let(:payload) { valid_payload.tap {|p| p.delete('error')} }
        it 'raises InvalidResponseError with descriptive message' do
          expect{subject}.to raise_error(Limeade::InvalidResponseError, 'Response body must have a result and an error')
        end
      end

      context 'when error is not a Hash' do
        let(:payload) { valid_payload.merge('error' => 'not a Hash')}
        it 'raises InvalidResponseError with descriptive message' do
          expect{subject}.to raise_error(Limeade::InvalidResponseError, 'Response error is not a Hash')
        end
      end
    end

    context 'with an error payload having the right bits' do
      let(:payload) { {'id'=>request_id, 'result'=>nil, 'error'=>error_payload} }
      let(:valid_error_payload) { {'code'=>3, 'message'=>'Hello World!'} }
      let(:error_payload) { valid_error_payload }

      it 'returns without raising an exception' do
        expect{subject}.not_to raise_error
      end

      context 'except without a code entry' do
        let(:error_payload) { valid_error_payload.tap {|p| p.delete('code')} }
        it 'raises InvalidResponseError with descriptive message' do
          expect{subject}.to raise_error(Limeade::InvalidResponseError, 'Response error is missing the code')
        end
      end

      context 'except the code is not an Integer' do
        let(:error_payload) { valid_error_payload.merge('code' => 'two')}
        it 'raises InvalidResponseError with descriptive message' do
          expect{subject}.to raise_error(Limeade::InvalidResponseError, 'Response error code is not a number')
        end
      end

      context 'except without a message entry' do
        let(:error_payload) { valid_error_payload.tap {|p| p.delete('message')} }
        it 'raises InvalidResponseError with descriptive message' do
          expect{subject}.to raise_error(Limeade::InvalidResponseError, 'Response error is missing the message')
        end
      end

      context 'except the code is not an Integer' do
        let(:error_payload) { valid_error_payload.merge('message' => 123)}
        it 'raises InvalidResponseError with descriptive message' do
          expect{subject}.to raise_error(Limeade::InvalidResponseError, 'Response error message is not a string')
        end
      end
    end
  end

  describe 'process_response' do
    subject do
      args = [response, request_id]
      instance.instance_eval {process_response(*args)}
    end

    let(:request_id) { 1 }
    let(:response) { Faraday::Response.new(body: payload) }

    context 'with a valid response' do
      let(:raw_payload) { {'id'=>request_id, 'result'=>'Hello World!', 'error'=>nil} }
      let(:payload) { raw_payload.to_json }

      it 'does not raise an exception' do
        expect{subject}.not_to raise_error
      end

      it 'returns the result from the payload' do
        expect(subject).to eq(raw_payload['result'])
      end
    end

    context 'with an error response' do
      let(:raw_payload) { {'id'=>request_id, 'result'=>nil, 'error'=>{'code'=>code, 'message'=>message}} }
      let(:payload) { raw_payload.to_json }
      let(:code) { 3 }
      let(:message) { 'my bad ...' }

      it 'raises a ServerError with the error code and message' do
        expect{subject}.to raise_error(Limeade::ServerError, /#{code}: #{message}/)
      end
    end
  end
end