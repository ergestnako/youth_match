class Compressor

  attr_reader :pool, :applicant, :run

  def initialize(pool)
    @pool = pool
    @run = @pool.run
    @applicant = @pool.applicant
    # Only select those pooled positions that are still available for
    # placement, since we are doing the compression at runtime and need to
    # base the compression off of the available positions at the time the
    # applicant is addressed.
    @pooled_positions = @pool.positions.select { |p| p.available?(@run) }
  end

  def compress!
    new_positions = positions.map do |position|
      PooledPosition.new(compressed: true, position: position)
    end
    @pool.positions << new_positions # Shovel operator saves relationships
    new_positions.count
  end

  def positions
    Position.compressible(@run).limit(position_gain)
  end

  def position_gain
    (gain.to_f / 100) * max_pool_position_count
  end

  def gain
    if signal < threshhold
      expected_output - signal
    else
      0
    end
  end

  def expected_output
    if signal < threshhold
      threshhold + ((signal - threshhold) / ratio)
    else
      signal
    end
  end

  def signal
    @signal ||= @pooled_positions.count.to_f / max_pool_position_count * 100
  end

  private

  def threshhold
    config.fetch(:threshhold)
  end

  def ratio
    config.fetch(:ratio)
  end

  def config
    @run.config.fetch(:compressor)
  end

  def max_pool_position_count
    @max ||= Pool.maximum :position_count
  end

end