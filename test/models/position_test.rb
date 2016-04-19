require 'test_helper'

class PositionTest < Minitest::Test

  def setup
    @position = position.dup
    @position.save!
    @run = Run.create!
    @applicant = Applicant.create!(grid_id: 1)
  end

  def position
    @_position ||= Position.new(grid_id: 1)
  end

  def teardown
    @position.destroy!
    @applicant.destroy!
    @run.destroy!
  end

  def test_valid
    assert position.valid?
  end

  def test_uuid
    assert_respond_to position, :uuid
    assert @position.reload.uuid
  end

  def test_category
    assert_respond_to position, :category
  end

  def test_addresses
    assert_respond_to position, :addresses
    assert_equal 'Hash', position.addresses.class.name
  end

  def test_address_components
    [:address, :state, :city, :street, :zip, :zip_5].each do |method|
      assert_respond_to position, method
    end
  end

  def test_grid_id
    assert_respond_to position, :grid_id
  end

  def test_travel_times
    assert_respond_to position, :travel_times
  end

  def test_positions
    %i( positions manual automatic ).each do |method|
      assert_respond_to position, method
    end
  end

  def test_unallocated_positions_can_be_whatever
    unallocated = Position.new(positions: 10, manual: nil, automatic: nil)
    assert unallocated.valid?, unallocated.errors.full_messages
    unallocated = Position.new(positions: 10, manual: 0, automatic: nil)
    refute unallocated.valid?
  end

  def test_allocated_positions_must_equal_total
    allocated = Position.new(positions: 10, manual: 5, automatic: 5)
    assert allocated.valid?, allocated.errors.full_messages
    allocated.positions = 9
    refute allocated.valid?
    allocated.positions = 11
    refute allocated.valid?
  end

  def test_allocations_must_both_be_present
    half = Position.new(positions: 10, manual: 10, automatic: nil)
    refute half.valid?
    half.automatic = 0
    assert half.valid?
  end

  def test_within
    @applicant.update_attribute(:grid_id, 1)
    @position.update_attribute(:grid_id, 2)
    @time = TravelTime.create!(input_id: 1, target_id: 2,
       travel_mode: :walking, time: 10.minutes, pair_id: 1)
    refute_empty within_10min_walk
    assert_includes within_10min_walk, @position
    assert_empty within_10min_transit
  ensure
    @time.destroy if time
  end

  def within_10min_walk
    Position.within(10.minutes, of: @applicant, via: :walking)
  end

  def within_10min_transit
    Position.within(10.minutes, of: @applicant, via: :transit)
  end

  def test_available
    before = Position.available(@run).count
    @p = @run.placements.create!(position: @position, applicant: @applicant, index: 1)
    after = Position.available(@run).count
    assert_equal 1, (before - after)
  ensure
    @p.destroy! if @p
  end

  def test_new_from_icims
    stub_job(id: 1123)
    stub_company
    expected = Position.new(id: 1123, categories: ['Education or Tutoring'], category: 'Education or Tutoring')
    new_position = Position.new_from_icims(ICIMS::Job.find(1123))
    assert_equal expected, new_position
  end

  def test_create_from_icims
    stub_job(id: 1123)
    stub_company
    created = Position.create_from_icims(ICIMS::Job.find(1123))
    assert_equal ['Education or Tutoring'], created.categories
    assert created.uuid
  ensure
    created.destroy! if created
  end

  private

  def stub_job(id: 1123)
    stub_request(:get, "https://api.icims.com/customers/6405/jobs/#{id}?fields=joblocation,jobtitle,numberofpositions,positioncategory").
      to_return(
        status: 200,
        body: File.read("./test/fixtures/icims/job-1123.json"),
        headers: { 'Content-Type' => 'application/json' })
  end

  def stub_company
    stub_request(:get, "https://api.icims.com/customers/6405/companies/1800").
      to_return(status: 200,
        body: File.read('./test/fixtures/icims/company-1800.json'),
        headers: { 'Content-Type' => 'application/json' })
  end

end
