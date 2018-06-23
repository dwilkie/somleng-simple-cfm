module DashboardHelper
  def nav_link(link_text, link_path, controller_names:, icon:)
    class_names = ["nav-link"]
    class_names << "active" if controller_names.include?(controller_name)

    content_tag(:li, class: "nav-item") do
      link_to(link_path, class: class_names.join(" ")) do
        fa_icon(icon, text: link_text)
      end
    end
  end

  def location_names(province_ids, type)
    Array(province_ids).map do |location_id|
      location = type.find_by_id(location_id)
      "#{location.name_km} (#{location.name_en})"
    end.join(", ")
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
