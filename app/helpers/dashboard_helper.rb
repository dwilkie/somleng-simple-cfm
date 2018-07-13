module DashboardHelper
  def batch_operation_create_phone_calls_default_filter_params
    default_batch_operation_filter_params = current_account.settings["batch_operation_phone_call_create_parameters"] || {}
    callout_participation_filter_params = default_batch_operation_filter_params["callout_participation_filter_params"] || {}
    callout_filter_params = default_batch_operation_filter_params.slice("callout_filter_params")
    callout_participation_filter_params.merge(callout_filter_params).presence
  end

  def location_names(province_ids, type)
    Array(province_ids).map do |location_id|
      location = type.find_by_id(location_id)
      "#{location.name_km} (#{location.name_en})" if location
    end.compact.join(", ")
  end

  def label_status(callout)
    label_class = case callout.status.to_sym
                  when Callout::STATE_RUNNING     then "badge-success"
                  when Callout::STATE_PAUSED      then "badge-warning"
                  when Callout::STATE_STOPPED     then "badge-danger"
                  when Callout::STATE_INITIALIZED then "badge-primary"
                  end
    content_tag(:span, class: "badge badge-pill #{label_class}") do
      callout.status.humanize
    end
  end
end
