require "rails_helper"

RSpec.describe "Users" do
  let(:user) { create(:user) }

  it "can list all users" do
    user = create(:user)
    other_user = create(:user, account: user.account)
    different_user = create(:user)

    sign_in(user)
    visit dashboard_users_path

    within("#button_toolbar") do
      expect(page).to have_link_to_action(
        :new, key: :user_invitations, href: new_user_invitation_path
      )
      expect(page).to have_link_to_action(:index, key: :users)
    end

    within("#resources") do
      expect(page).to have_content("#")

      expect(page).to have_link(
        other_user.id,
        href: dashboard_user_path(other_user)
      )

      expect(page).to have_content("Email")
      expect(page).to have_content(user.email)
      expect(page).to have_content(other_user.email)
      expect(page).to have_no_content(different_user.email)
      expect(page).to have_content("Last sign in at")
      expect(page).to have_content("Invitation accepted at")
    end
  end

  it "can show a user" do
    user = create(:user)

    sign_in(user)
    visit dashboard_user_path(user)

    within("#button_toolbar") do
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

  it "can update a user" do
    user = create(:user)
    other_user = create(:user, account: user.account)

    sign_in(user)
    visit edit_dashboard_user_path(other_user)

    within("#button_toolbar") do
      expect(page).to have_link_to_action(
        :edit,
        key: :users,
        href: edit_dashboard_user_path(other_user)
      )
    end

    expect(page).to have_link_to_action(:cancel)

    fill_in_key_value_for(:metadata, with: { key: "name", value: "Bob Chann" })
    click_action_button(:update, key: :submit, namespace: :helpers)

    expect(current_path).to eq(dashboard_user_path(other_user))
    expect(page).to have_text("User was successfully updated.")
    expect(other_user.reload.metadata).to eq("name" => "Bob Chann")
  end

  it "can delete a user" do
    user = create(:user)
    other_user = create(:user, account: user.account)

    sign_in(user)
    visit dashboard_user_path(other_user)

    within("#button_toolbar") do
      click_action_button(:delete, type: :link)
    end

    expect(current_path).to eq(dashboard_users_path)
    expect(page).to have_text("User was successfully destroyed.")
  end
end
