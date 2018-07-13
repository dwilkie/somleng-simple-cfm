require "rails_helper"

RSpec.describe "Users" do
  context "when a user is not an admin tries to users page" do
    let(:user) { create(:user) }

    it "render page 401" do
      sign_in(user)

      visit dashboard_users_path

      expect(page).to have_text("We're sorry, but you do not have permission to view this page.")
    end
  end

  it "can list all users" do
    user = create(:admin)
    other_user = create(:user, account: user.account)

    sign_in(user)
    visit dashboard_users_path

    expect(page).to have_title("Users")

    within("#page_actions") do
      expect(page).to have_link_to_action(
        :new, key: :user_invitations, href: new_user_invitation_path
      )
    end

    within("#resources") do
      expect(page).to have_content("#")

      expect(page).to have_link(
        other_user.id,
        href: dashboard_user_path(other_user)
      )

      expect(page).to have_sortable_column("email")
      expect(page).to have_sortable_column("invitation_accepted_at")
      expect(page).to have_sortable_column("last_sign_in_at")
      expect(page).to have_sortable_column("created_at")
      expect(other_user.email).to appear_before(user.email)
    end

    click_link("Created at")

    within("#resources") do
      expect(user.email).to appear_before(other_user.email)
    end
  end

  it "can show a user" do
    user = create(:admin)

    sign_in(user)
    visit dashboard_user_path(user)

    expect(page).to have_title("User #{user.id}")

    within("#page_actions") do
      expect(page).to have_link_to_action(
        :edit,
        href: edit_dashboard_user_path(user)
      )
    end

    within("#user") do
      expect(page).to have_content("#")
      expect(page).to have_content(user.id)
      expect(page).to have_content("Email")
      expect(page).to have_content(user.email)
      expect(page).to have_content("Created at")
      expect(page).to have_content("Last sign in at")
      expect(page).to have_content("Invitation accepted at")
    end
  end

  it "can update a user", :js do
    user = create(:admin)
    other_user = create(:user, account: user.account)

    sign_in(user)
    visit edit_dashboard_user_path(other_user)

    expect(page).to have_title("Edit User")

    choose "Admin"
    multiple_selectize("#locations", "Banteay Meanchey")
    click_action_button(:update, key: :submit, namespace: :helpers)

    other_user.reload
    expect(current_path).to eq(dashboard_user_path(other_user))
    expect(page).to have_text("User was successfully updated.")
    expect(other_user.roles?(:admin)).to eq true
    expect(other_user.province_ids).to include_location("Banteay Meanchey")
  end

  it "can delete a user" do
    user = create(:admin)
    other_user = create(:user, account: user.account)

    sign_in(user)
    visit dashboard_user_path(other_user)

    within("#page_actions") do
      click_action_button(:delete, type: :link)
    end

    expect(current_path).to eq(dashboard_users_path)
    expect(page).to have_text("User was successfully destroyed.")
  end
end
