require "application_system_test_case"

class VarTypesTest < ApplicationSystemTestCase
  setup do
    @var_type = var_types(:one)
  end

  test "visiting the index" do
    visit var_types_url
    assert_selector "h1", text: "Var types"
  end

  test "should create var type" do
    visit var_types_url
    click_on "New var type"

    click_on "Create Var type"

    assert_text "Var type was successfully created"
    click_on "Back"
  end

  test "should update Var type" do
    visit var_type_url(@var_type)
    click_on "Edit this var type", match: :first

    click_on "Update Var type"

    assert_text "Var type was successfully updated"
    click_on "Back"
  end

  test "should destroy Var type" do
    visit var_type_url(@var_type)
    click_on "Destroy this var type", match: :first

    assert_text "Var type was successfully destroyed"
  end
end
