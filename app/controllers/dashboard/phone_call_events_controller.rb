class Dashboard::PhoneCallEventsController < Dashboard::EventsController
  private

  def prepare_resource_for_create
    phone_call.subscribe(PhoneCallObserver.new)
  end

  def parent
    phone_call
  end

  def phone_call
    @phone_call ||= current_account.phone_calls.find(params[:phone_call_id])
  end

  def event_class
    Event::PhoneCall
  end
end
