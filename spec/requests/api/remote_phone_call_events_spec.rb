require "rails_helper"

RSpec.describe "Remote Phone Call Events" do
  include SomlengScfm::SpecHelpers::RequestHelpers

  let(:account_traits) { {} }
  let(:account_attributes) { {} }
  let(:account) { create(:account, *account_traits.keys, account_attributes) }
  let(:access_token_model) { create(:access_token, resource_owner: account) }

  let(:callout_attributes) { { account: account } }
  let(:callout) { create(:callout, callout_attributes) }

  let(:contact_attributes) { { account: account } }
  let(:contact) { create(:contact, contact_attributes) }

  let(:callout_participation_attributes) { { callout: callout, contact: contact } }
  let(:callout_participation) { create(:callout_participation, callout_participation_attributes) }

  let(:phone_call_attributes) { { callout_participation: callout_participation } }
  let(:phone_call) { create(:phone_call, phone_call_attributes) }

  let(:factory_attributes) { { phone_call: phone_call } }
  let(:remote_phone_call_event) { create(:remote_phone_call_event, factory_attributes) }

  let(:execute_request) { true }
  let(:body) { {} }
  let(:headers) { {} }

  def execute_request!
    do_request(method, url, body, headers)
  end

  def setup_scenario
    super
    execute_request! if execute_request
  end

  describe "'/api/remote_phone_call_events/:id'" do
    let(:url) { api_remote_phone_call_event_path(remote_phone_call_event) }

    describe "GET" do
      let(:method) { :get }

      def assert_show!
        expect(response.code).to eq("200")
        expect(JSON.parse(response.body)).to eq(JSON.parse(remote_phone_call_event.to_json))
      end

      it { assert_show! }
    end

    describe "PATCH" do
      let(:method) { :patch }
      let(:factory_attributes) { super().merge("metadata" => { "bar" => "baz" }) }
      let(:metadata) { { "foo" => "bar" } }
      let(:body) do
        {
          metadata: metadata,
          metadata_merge_mode: "replace"
        }
      end

      def assert_update!
        expect(response.code).to eq("204")
        expect(remote_phone_call_event.reload.metadata).to eq(metadata)
      end

      it { assert_update! }
    end
  end

  describe "'/api/remote_phone_call_events'" do
    let(:url_params) { {} }
    let(:url) { api_remote_phone_call_events_url(url_params) }

    describe "GET" do
      let(:method) { :get }

      it_behaves_like "resource_filtering" do
        let(:filter_on_factory) { :remote_phone_call_event }
        let(:filter_factory_attributes) { factory_attributes }
      end

      it_behaves_like "authorization"
    end

    describe "POST" do
      let(:method) { :post }
      let(:call_sid) { SecureRandom.hex }
      let(:from) { nil }
      let(:to) { nil }
      let(:direction) { nil }
      let(:call_status) { nil }

      let(:twilio_account_sid) { generate(:twilio_account_sid) }
      let(:somleng_account_sid) { SecureRandom.hex }
      let(:twilio_auth_token) { SecureRandom.hex }
      let(:somleng_auth_token) { SecureRandom.hex }

      let(:request_account_sid) { twilio_account_sid }
      let(:request_auth_token) { twilio_auth_token }

      let(:twilio_request_validator) do
        Twilio::Security::RequestValidator.new(request_auth_token)
      end

      let(:twilio_request_signature) do
        twilio_request_validator.build_signature_for(url, body)
      end

      let(:authorization_user) { nil }
      let(:authorization_password) { nil }

      let(:account_attributes) do
        super().merge(
          twilio_account_sid: twilio_account_sid,
          twilio_auth_token: twilio_auth_token,
          somleng_account_sid: somleng_account_sid,
          somleng_auth_token: somleng_auth_token
        )
      end

      def body
        {
          "CallSid" => call_sid,
          "From" => from,
          "To" => to,
          "Direction" => direction,
          "CallStatus" => call_status,
          "AccountSid" => request_account_sid
        }
      end

      def headers
        {
          "X-Twilio-Signature" => twilio_request_signature
        }
      end

      context "requesting json" do
        let(:url_params) { { format: :json } }
        let(:execute_request) { false }
        let(:asserted_response_body) { asserted_remote_phone_call_event.to_json }
        it { expect { execute_request! }.to raise_error(ActionController::UnknownFormat) }
      end

      context "unauthorized request" do
        let(:twilio_request_signature) { "wrong" }

        def assert_unauthorized!
          expect(response.code).to eq("403")
        end

        it { assert_unauthorized! }
      end

      context "invalid request" do
        def assert_invalid!
          expect(response.code).to eq("422")
          xml_response = Hash.from_xml(response.body)
          expect(xml_response["errors"]).to be_present
        end

        it { assert_invalid! }
      end

      context "valid request" do
        let(:application_twiml) { CallFlowLogic::HelloWorld.new(asserted_remote_phone_call_event).to_xml }
        let(:asserted_twiml) { application_twiml }
        let(:asserted_response_body) { asserted_twiml }
        let(:asserted_remote_phone_call_event) { RemotePhoneCallEvent.last }

        def assert_created!
          expect(response.code).to eq("201")
          expect(response.headers).not_to have_key("Location")
          expect(asserted_remote_phone_call_event.details).to eq(body)
          expect(asserted_phone_call.reload).to be_present
          expect(asserted_phone_call.status).to eq(asserted_phone_call_status.to_s)
          expect(asserted_phone_call.remote_call_id).to eq(call_sid)
          expect(asserted_phone_call.remote_direction).to eq(direction)
          expect(asserted_phone_call.remote_status).to eq(call_status)
          expect(asserted_contact).to be_present
          expect(asserted_contact.msisdn).to eq(asserted_contact_msisdn)
          expect(response.body).to eq(asserted_response_body)
        end

        context "with registered call flow logic" do
          let(:call_flow_logic) { nil }
          let(:my_callflow_logic_twiml) do
            MyCallFlowLogic.new(asserted_remote_phone_call_event).to_xml
          end

          class MyCallFlowLogic < CallFlowLogic::Base
            def to_xml(_options = {})
              Twilio::TwiML::VoiceResponse.new do |response|
                response.say("Thanks for trying my custom call flow logic. Enjoy")
              end.to_s
            end
          end

          def setup_scenario
            CallFlowLogic::Base.register(call_flow_logic.to_s)
            super
          end

          context "for an inbound call" do
            let(:from) { "+85510202101" }
            let(:to) { "345" }
            let(:direction) { "inbound" }
            let(:call_status) { "in-progress" }

            let(:asserted_phone_call) { asserted_remote_phone_call_event.phone_call }
            let(:asserted_phone_call_status) { PhoneCall::STATE_IN_PROGRESS }
            let(:asserted_contact) { asserted_phone_call.contact }
            let(:asserted_contact_msisdn) { from }

            context "by default" do
              it { assert_created! }
            end

            context "setting the default call flow logic" do
              let(:call_flow_logic) { MyCallFlowLogic }
              let(:asserted_twiml) { my_callflow_logic_twiml }
              let(:execute_request) { false }

              def setup_scenario
                super
                account.update_attributes!(call_flow_logic: MyCallFlowLogic.to_s)
                execute_request!
              end

              it { assert_created! }
            end
          end

          context "for an outbound call" do
            let(:from) { "345" }
            let(:to) { "+85510202101" }
            let(:direction) { "outbound-api" }
            let(:call_status) { "ringing" }

            let(:contact) { create(:contact) }
            let(:callout) { create(:callout, call_flow_logic: call_flow_logic) }
            let(:callout_participation) { create(:callout_participation, callout: callout) }
            let(:asserted_phone_call_status) { PhoneCall::STATE_IN_PROGRESS }

            let(:phone_call) do
              create(
                :phone_call,
                remote_call_id: call_sid,
                remote_direction: direction,
                contact: contact,
                callout_participation: callout_participation
              )
            end

            let(:asserted_phone_call) { phone_call }
            let(:asserted_contact) { contact }
            let(:asserted_contact_msisdn) { contact.msisdn }

            def setup_scenario
              super
              phone_call
              execute_request!
            end

            context "setting the call_flow_logic to a valid class" do
              let(:execute_request) { false }
              let(:call_flow_logic) { MyCallFlowLogic }
              let(:asserted_twiml) { my_callflow_logic_twiml }
              it { assert_created! }
            end

            context "not setting the call_flow_logic" do
              it { assert_created! }
            end
          end
        end
      end
    end
  end

  describe "nested indexes" do
    let(:method) { :get }

    def setup_scenario
      create(
        :remote_phone_call_event,
        phone_call: create(
          :phone_call,
          callout_participation: create(
            :callout_participation,
            callout: create(
              :callout,
              account: account
            )
          )
        )
      )
      remote_phone_call_event
      super
    end

    def assert_filtered!
      expect(JSON.parse(response.body)).to eq(JSON.parse([remote_phone_call_event].to_json))
    end

    describe "GET '/api/phone_calls/:phone_call_id/remote_phone_call_events'" do
      let(:url) { api_phone_call_remote_phone_call_events_path(phone_call) }
      it { assert_filtered! }
    end

    describe "GET '/api/callout_participations/:callout_participation_id/remote_phone_call_events'" do
      let(:url) { api_callout_participation_remote_phone_call_events_path(callout_participation) }
      it { assert_filtered! }
    end

    describe "GET '/api/callout/:callout_id/remote_phone_call_events'" do
      let(:url) { api_callout_remote_phone_call_events_path(callout) }
      it { assert_filtered! }
    end

    describe "GET '/api/contact/:contact_id/remote_phone_call_events'" do
      let(:url) { api_contact_remote_phone_call_events_path(contact) }
      it { assert_filtered! }
    end
  end
end
