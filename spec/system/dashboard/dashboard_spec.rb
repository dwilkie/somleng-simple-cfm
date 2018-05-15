require "rails_helper"

RSpec.describe "Dashboard" do
  it "has side navigation links" do
    user = create(:user)
    sign_in(user)
    visit(root_path)

    within("#side_navigation") do
      expect(page).to have_link(
        I18n.translate!(:"titles.callouts.index"),
        href: dashboard_callouts_path
      )

      expect(page).to have_link(
        I18n.translate!(:"titles.contacts.index"),
        href: dashboard_contacts_path
      )

      expect(page).to have_link(
        I18n.translate!(:"titles.access_tokens.index"),
        href: dashboard_access_tokens_path
      )

      expect(page).to have_link(
        I18n.translate!(:"titles.users.index"),
        href: dashboard_users_path
      )

      expect(page).to have_link(
        I18n.translate!(:"titles.batch_operations.index"),
        href: dashboard_batch_operations_path
      )
    end
  end
end
