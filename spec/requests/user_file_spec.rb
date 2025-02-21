require 'rails_helper'

RSpec.describe 'user filestore API', type: :request do
  let(:service_slug) { 'my-service' }
  let(:user_identifier) { SecureRandom::uuid }
  let(:headers) do
    { 'content-type' => 'application/json' }
  end

  describe 'POST /service/:service_slug/:user/:user_identifier' do
    let(:post_request) do
      post url, params: params.to_json, headers: headers
    end

    context 'to /service/:service_slug/user/:user_identifier' do
      let(:url) { "/service/#{service_slug}/user/#{user_identifier}" }

      it_behaves_like 'a JWT-authenticated method', :post, '/service/:service_slug/user/:user_identifier', { checksum: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" }

      context 'with a valid token' do
        before do
          allow_any_instance_of(UploadsController).to receive(:verify_token!)
        end
      end
    end
  end

  describe 'request error messages' do
    context 'exception TokenNotValidError raised' do
      before do
        allow_any_instance_of(UploadsController).to receive(:verify_token!).and_raise(Exceptions::TokenNotValidError)
        post "/service/#{service_slug}/user/#{user_identifier}"
      end

      it 'returns a 403 status' do
        expect(response).to have_http_status(403)
      end

      it 'returns json error message' do
        expect(json['errors'].first['title']).to eq(I18n.t('error_messages.token_not_valid.title'))
      end
    end

    context 'exception TokenNotPresentError raised' do
      before do
        allow_any_instance_of(UploadsController).to receive(:verify_token!).and_raise(Exceptions::TokenNotPresentError)
        post "/service/#{service_slug}/user/#{user_identifier}"
      end

      it 'returns a 401 status' do
        expect(response).to have_http_status(401)
      end

      it 'returns json error message' do
        expect(json['errors'].first['title']).to eq(I18n.t('error_messages.token_not_present.title'))
      end
    end

    context 'exception InternalServerError raised' do
      before do
        allow_any_instance_of(UploadsController).to receive(:verify_token!).and_raise(StandardError)
        post "/service/#{service_slug}/user/#{user_identifier}"
      end
      it 'returns a 500 status' do
        expect(response).to have_http_status(500)
      end

      it 'returns json error message' do
        expect(json['errors'].first['title']).to eq(I18n.t('error_messages.internal_server_error.title'))
      end
    end
  end
end
