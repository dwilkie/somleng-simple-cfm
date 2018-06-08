require "rails_helper"

RSpec.describe "Callouts", :aggregate_failures do
  it "can list callouts" do
    user          = create(:user)
    callout       = create(:callout, :initialized, account: user.account)
    other_callout = create(:callout)

    sign_in(user)
    visit dashboard_callouts_path

    expect(page).to have_title("Callouts")

    within("#button_toolbar") do
      expect(page).to have_link_to_action(
        :new, key: :callouts, href: new_dashboard_callout_path
      )
      expect(page).to have_link_to_action(:index, key: :callouts)
    end

    within("#resources") do
      expect(page).to have_content_tag_for(callout)
      expect(page).not_to have_content_tag_for(other_callout)
      expect(page).to have_content("#")
      expect(page).to have_link(
        callout.id,
        href: dashboard_callout_path(callout)
      )
      expect(page).to have_sortable_column("status")
      expect(page).to have_sortable_column("created_at")
      expect(page).to have_content("Initialized")
    end
  end

  it "can create a callout" do
    user = create(:user)

    sign_in(user)
    visit new_dashboard_callout_path

    expect(page).to have_title("New Callout")

    within("#button_toolbar") do
      expect(page).to have_link(
        I18n.translate!(:"titles.callouts.new"),
        href: new_dashboard_callout_path
      )
    end

    expect(page).to have_link_to_action(:cancel)

    choose("Hello World")
    fill_in_key_value_for(:metadata, with: { key: "location:country", value: "kh" })
    click_action_button(:create, key: :submit, namespace: :helpers, model: "Callout")

    new_callout = Callout.last!
    expect(current_path).to eq(dashboard_callout_path(new_callout))
    expect(page).to have_text("Callout was successfully created.")
    expect(new_callout.account).to eq(user.account)
    expect(new_callout.call_flow_logic).to eq(CallFlowLogic::HelloWorld.to_s)
    expect(new_callout.metadata).to eq("location" => { "country" => "kh" })
  end

  it "can update a callout", :js do
    user = create(:user)
    callout = create(
      :callout,
      account: user.account,
      metadata: { "location" => { "country" => "kh", "city" => "Phnom Penh" } }
    )

    sign_in(user)
    visit edit_dashboard_callout_path(callout)

    expect(page).to have_title("Edit Callout")

    within("#button_toolbar") do
      expect(page).to have_link(
        I18n.translate!(:"titles.callouts.edit"),
        href: edit_dashboard_callout_path(callout)
      )
    end

    expect(page).to have_link_to_action(:cancel)

    choose("Hello World")
    remove_key_value_for(:metadata)
    remove_key_value_for(:metadata)
    click_action_button(:update, key: :submit, namespace: :helpers)

    expect(current_path).to eq(dashboard_callout_path(callout))
    expect(page).to have_text("Callout was successfully updated.")
    expect(callout.reload.metadata).to eq({})
    expect(callout.call_flow_logic).to eq(CallFlowLogic::HelloWorld.to_s)
  end

  it "can delete a callout" do
    user = create(:user)
    callout = create(:callout, account: user.account)

    sign_in(user)
    visit dashboard_callout_path(callout)

    click_action_button(:delete, type: :link)

    expect(current_path).to eq(dashboard_callouts_path)
    expect(page).to have_text("Callout was successfully destroyed.")
  end

  it "can show a callout" do
    user = create(:user)
    callout = create(
      :callout,
      :initialized,
      account: user.account,
      call_flow_logic: "CallFlowLogic::HelloWorld",
      metadata: { "location" => { "country" => "Cambodia" } }
    )

    sign_in(user)
    visit dashboard_callout_path(callout)

    expect(page).to have_title("Callout #{callout.id}")

    within("#button_toolbar") do
      expect(page).to have_link_to_action(
        :edit,
        href: edit_dashboard_callout_path(callout)
      )

      expect(page).to have_link_to_action(
        :index,
        key: :batch_operations,
        href: dashboard_callout_batch_operations_path(callout)
      )

      expect(page).to have_link_to_action(
        :index,
        key: :callout_participations,
        href: dashboard_callout_callout_participations_path(callout)
      )

      expect(page).to have_link_to_action(
        :index,
        key: :phone_calls,
        href: dashboard_callout_phone_calls_path(callout)
      )
    end

    within("#callout") do
      expect(page).to have_content(callout.id)
      expect(page).to have_content("Status")
      expect(page).to have_content("Initialized")
      expect(page).to have_content("Created at")
      expect(page).to have_content("Call flow logic")
      expect(page).to have_content("CallFlowLogic::HelloWorld")
      expect(page).to have_content("Metadata")
      expect(page).to have_content("location:country")
      expect(page).to have_content("Cambodia")
    end
  end

  it "can perform actions on callouts" do
    user = create(:user)
    callout = create(
      :callout,
      :initialized,
      account: user.account
    )

    sign_in(user)
    visit dashboard_callout_path(callout)

    click_action_button(:start_callout, key: :callouts, type: :link)

    expect(callout.reload).to be_running
    expect(page).to have_text("Event was successfully created.")
    expect(page).not_to have_link_to_action(:start_callout, key: :callouts)

    click_action_button(:stop_callout, key: :callouts, type: :link)

    expect(callout.reload).to be_stopped
    expect(page).not_to have_link_to_action(:stop_callout, key: :callouts)

    click_action_button(:resume_callout, key: :callouts, type: :link)

    expect(callout.reload).to be_running
    expect(page).not_to have_link_to_action(:resume_callout, key: :callouts)
    expect(page).to have_link_to_action(:stop_callout, key: :callouts)
  end
end
