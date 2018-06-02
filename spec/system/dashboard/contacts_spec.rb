require "rails_helper"

RSpec.describe "Contacts", :aggregate_failures do
  it "can list all contacts" do
    user = create(:admin)
    contact = create(:contact, account: user.account)
    other_contact = create(:contact)

    sign_in(user)
    visit dashboard_contacts_path

    within("#button_toolbar") do
      expect(page).to have_link_to_action(
        :new, key: :contacts, href: new_dashboard_contact_path
      )
      expect(page).to have_link_to_action(:index, key: :contacts)
    end

    within("#resources") do
      expect(page).to have_content_tag_for(contact)
      expect(page).not_to have_content_tag_for(other_contact)
      expect(page).to have_content("#")
      expect(page).to have_link(
        contact.id,
        href: dashboard_contact_path(contact)
      )
      expect(page).to have_content("Phone number")
    end
  end

  it "can create a new contact", :js do
    user = create(:admin)
    phone_number = generate(:somali_msisdn)

    sign_in(user)
    visit new_dashboard_contact_path

    within("#button_toolbar") do
      expect(page).to have_link(
        I18n.translate!(:"titles.contacts.new"),
        href: new_dashboard_contact_path
      )
    end

    expect(page).to have_link_to_action(:cancel)

    click_action_button(:create, key: :submit, namespace: :helpers, model: "Contact")

    expect(page).to have_content("Phone number can't be blank")

    fill_in_contact_information(phone_number)
    click_action_button(:create, key: :submit, namespace: :helpers, model: "Contact")

    expect(page).to have_text("Contact was successfully created.")
    new_contact = user.reload.account.contacts.last!
    expect(new_contact.msisdn).to match(phone_number)
  end

  it "can update a contact", :js do
    user = create(:admin)
    contact = create(
      :contact,
      account: user.account
    )

    sign_in(user)
    visit edit_dashboard_contact_path(contact)

    within("#button_toolbar") do
      expect(page).to have_link(
        I18n.translate!(:"titles.contacts.edit"),
        href: edit_dashboard_contact_path(contact)
      )
    end

    expect(page).to have_link_to_action(:cancel)

    updated_phone_number = generate(:somali_msisdn)
    fill_in_contact_information(updated_phone_number)
    click_action_button(:update, key: :submit, namespace: :helpers)

    expect(current_path).to eq(dashboard_contact_path(contact))
    expect(page).to have_text("Contact was successfully updated.")
    expect(contact.reload.msisdn).to match(updated_phone_number)
  end

  it "can delete a contact" do
    user = create(:admin)
    contact = create(:contact, account: user.account)

    sign_in(user)
    visit dashboard_contact_path(contact)

    click_action_button(:delete, type: :link)

    expect(current_path).to eq(dashboard_contacts_path)
    expect(page).to have_text("Contact was successfully destroyed.")
  end

  it "can show a contact" do
    user = create(:admin)
    phone_number = generate(:somali_msisdn)
    contact = create(
      :contact,
      account: user.account,
      msisdn: phone_number
    )

    sign_in(user)
    visit dashboard_contact_path(contact)

    within("#button_toolbar") do
      expect(page).to have_link_to_action(
        :edit,
        href: edit_dashboard_contact_path(contact)
      )

      expect(page).to have_link_to_action(
        :index,
        key: :callout_participations,
        href: dashboard_contact_callout_participations_path(contact)
      )

      expect(page).to have_link_to_action(
        :index,
        key: :phone_calls,
        href: dashboard_contact_phone_calls_path(contact)
      )
    end

    within("#contact") do
      expect(page).to have_content(contact.id)
      expect(page).to have_content("#")
      expect(page).to have_content("Phone number")
      expect(page).to have_content(phone_number)
    end
  end

  def fill_in_contact_information(phone_number)
    fill_in("Phone number", with: phone_number)
    select_selectize("#province", "Battambang")
    select_selectize("#district", "Banan")
    select_selectize("#commune", "Kantueu Pir")
  end
end
