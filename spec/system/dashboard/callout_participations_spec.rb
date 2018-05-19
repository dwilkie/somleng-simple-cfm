require "rails_helper"

RSpec.describe "Callout Participations" do
  it "can list all callout participations for a callout" do
    user = create(:user)
    callout_participation = create_callout_participation(user.account)
    other_callout_participation = create_callout_participation(user.account)

    sign_in(user)
    visit(dashboard_callout_callout_participations_path(callout_participation.callout))

    within("#button_toolbar") do
      expect(page).to have_link_to_action(:index, key: :callout_participations)
      expect(page).to have_link_to_action(
        :back, href: dashboard_callout_path(callout_participation.callout)
      )
    end

    within("#resources") do
      expect(page).to have_content_tag_for(callout_participation)
      expect(page).not_to have_content_tag_for(other_callout_participation)
      expect(page).to have_content("#")
      expect(page).to have_link(
        callout_participation.id,
        href: dashboard_callout_participation_path(callout_participation)
      )
    end
  end

  it "can list all the callout participations for a callout population" do
    user = create(:user)
    callout_population = create(:callout_population, account: user.account)
    callout_participation = create_callout_participation(
      user.account,
      callout: callout_population.callout,
      callout_population: callout_population
    )

    other_callout_participation = create_callout_participation(
      user.account,
      callout: callout_population.callout
    )

    sign_in(user)
    visit(dashboard_batch_operation_callout_participations_path(callout_population))

    within("#button_toolbar") do
      expect(page).to have_link_to_action(
        :back, href: dashboard_batch_operation_path(callout_population)
      )
    end

    within("#resources") do
      expect(page).to have_content_tag_for(callout_participation)
      expect(page).not_to have_content_tag_for(other_callout_participation)
    end
  end

  it "can list all the callout participations for a contact" do
    user = create(:user)
    callout_participation = create_callout_participation(user.account)
    other_callout_participation = create_callout_participation(user.account)

    sign_in(user)
    visit(dashboard_contact_callout_participations_path(callout_participation.contact))

    within("#button_toolbar") do
      expect(page).to have_link_to_action(
        :back, href: dashboard_contact_path(callout_participation.contact)
      )
    end

    within("#resources") do
      expect(page).to have_content_tag_for(callout_participation)
      expect(page).not_to have_content_tag_for(other_callout_participation)
    end
  end

  it "can show a callout participation" do
    user = create(:user)
    callout_population = create(:callout_population, account: user.account)
    callout_participation = create_callout_participation(
      user.account,
      callout: callout_population.callout,
      callout_population: callout_population
    )

    sign_in(user)
    visit(dashboard_callout_participation_path(callout_participation))

    within("#resource") do
      expect(page).to have_content(callout_participation.id)

      expect(page).to have_link(
        callout_participation.callout_id,
        href: dashboard_callout_path(callout_participation.callout)
      )

      expect(page).to have_link(
        callout_participation.contact_id,
        href: dashboard_contact_path(callout_participation.contact)
      )

      expect(page).to have_link(
        callout_participation.callout_population_id,
        href: dashboard_batch_operation_path(callout_participation.callout_population)
      )

      expect(page).to have_content("Callout")
      expect(page).to have_content("Contact")
      expect(page).to have_content("Callout Population")
      expect(page).to have_content("Created at")
    end
  end

  it "can delete a callout participation" do
    user = create(:user)
    callout_participation = create_callout_participation(user.account)

    sign_in(user)
    visit dashboard_callout_participation_path(callout_participation)

    click_action_button(:delete, type: :link)

    expect(current_path).to eq(dashboard_callout_callout_participations_path(callout_participation.callout))
    expect(page).to have_text("Callout Participation was successfully destroyed.")
  end

  def create_callout_participation(account, *args)
    options = args.extract_options!
    callout = options.delete(:callout) || create(:callout, account: account)
    contact = options.delete(:contact) || create(:contact, account: account)
    create(:callout_participation, *args, { callout: callout, contact: contact }.merge(options))
  end
end
