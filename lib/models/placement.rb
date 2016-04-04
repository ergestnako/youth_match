class Placement < ActiveRecord::Base

  extend Enumerize

  belongs_to :run
  belongs_to :applicant
  belongs_to :position

  validates :run,       presence: true
  validates :applicant, presence: true
  validates :index,     presence: true

  enumerize :status, in: [:pending, :accepted, :declined, :expired],
    default: :pending, predicates: true

  def accepted
    update_attribute(:status, :accepted)
  end

  def declined
    update_attribute(:status, :declined)
  end

  def expired
    update_attribute(:status, :expired)
  end

  def travel_time
    return nil if position.nil? # May have introduced a stats bug
    TravelTime.where(
      target_id: position.grid_id,
      input_id: applicant.grid_id,
      travel_mode: applicant.mode
    ).first.time
  end

end
