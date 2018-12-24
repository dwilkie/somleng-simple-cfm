module Filter
  module Resource
    class CalloutParticipation < Filter::Resource::Msisdn
      def self.attribute_filters
        super <<
          :has_phone_calls_scope <<
          :last_phone_call_attempt_scope <<
          :no_phone_calls_or_last_attempt_scope <<
          :having_max_phone_calls_count_scope <<
          :callout_scope
      end

      private

      def filter_params
        params.slice(:call_flow_logic, :callout_id, :contact_id, :callout_population_id)
      end

      def has_phone_calls_scope
        Filter::Scope::HasPhoneCalls.new(options, params)
      end

      def last_phone_call_attempt_scope
        Filter::Scope::LastPhoneCallAttempt.new(options, params)
      end

      def no_phone_calls_or_last_attempt_scope
        Filter::Scope::NoPhoneCallsOrLastAttempt.new(options, params)
      end

      def having_max_phone_calls_count_scope
        Filter::Scope::HavingMaxPhoneCallsCount.new(options, params)
      end

      def callout_scope
        Filter::Scope::Callout.new(options, params)
      end
    end
  end
end
