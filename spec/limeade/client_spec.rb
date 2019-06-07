require 'spec_helper'

RSpec.describe Limeade::Client do

  let(:instance) { described_class.new(endpoint, username, password) }
  let(:endpoint) { ENV['LIMESURVEY_ENDPOINT'] || raise('Set up environment variables. See README file Development section.') }
  let(:username) { ENV['LIMESURVEY_ACCOUNT'] || raise('Set up environment variables. See README file Development section.') }
  let(:password) { ENV['LIMESURVEY_PASSWORD'] || raise('Set up environment variables. See README file Development section.') }
  let(:survey_id) { ENV['LIMESURVEY_SURVEY_ID'] || raise('Set up environment variables. See README file Development section.') }

  describe 'new' do
    subject { described_class.new(endpoint, username, password) }

    context 'with the proper credentials' do
      # Use default credentials defined above.
      it 'instantiates the client with a session key' do
        expect(subject).to be_a(Limeade::Client)
        expect(subject.instance_variable_get(:@session_key)).to be_a(String)
      end
    end

    context 'with an invalid username' do
      let(:username) { 'fester_bestertester' }

      it 'raises an exception' do
        expect{subject}.to raise_error(Limeade::InvalidCredentialsError)
      end
    end

    context 'with an invalid password' do
      let(:password) { 'invalid' }

      it 'raises an exception' do
        expect{subject}.to raise_error(Limeade::InvalidCredentialsError)
      end
    end
  end

  describe 'calling a method with no params: list_surveys' do
    subject { instance.list_surveys }

    it 'returns an Array of surveys' do
      expect(subject).to be_a(Array)
      survey = subject.first
      expect(survey.keys).to include('sid')
      expect(survey.keys).to include('surveyls_title')
      expect(survey.keys).to include('startdate')
      expect(survey.keys).to include('expires')
      expect(survey.keys).to include('active')
    end
  end

  describe 'calling a method with params: get_summary' do
    subject { instance.get_summary(*[survey_id, field_name].compact) }

    context 'with an extant survey' do

      context 'and no field name' do
        let(:field_name) { nil }
        it 'returns a Hash with statistics' do
          expect(subject).to be_a(Hash)
          expect(subject.keys).to include('completed_responses')
          expect(subject.keys).to include('full_responses')
          expect(subject.keys).to include('incomplete_responses')
        end
      end

      context 'and a field name' do
        let(:field_name) { 'completed_responses' }
        it 'returns a String with the requested statistic' do
          expect(subject).to be_a(String)
        end
      end
    end

    context 'with an unknown survey' do
      let(:survey_id) { 1 }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end