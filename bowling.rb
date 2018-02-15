class BowlingError < StandardError
end

class Game
  attr_accessor :status, :scoring, :score, :counter, :throws, :frames, :pins, :frame

  def initialize
    @status = :open
    @scoring = []
    @score = 0
    @counter = 0
    @throws = 0
    @frames = (0..9).to_a.map { |_e| Frame.new }
    @pins = nil
    @frame = nil
  end

  def roll(pins)
    @pins = pins
    game_or_frame_valid?

    @scoring << @pins
    @throws += 1
    @frame = @frames[@counter]
    @frame.score += @pins

    score_pins
  end

  def score
    if @frames.map(&:type).all? { |e| e != :undefined }
      @score
    else
      raise BowlingError
    end
  end

  private

  def game_or_frame_valid?
    raise BowlingError if (@pins < 0) || (@pins > 10)
    raise BowlingError if @status == :closed
  end

  def score_pins
    strike_not_in_last_frame?
    spare_or_open_frame?
    last_frame?
  end

  def strike_not_in_last_frame?
    if (@throws == 1) && (@pins == 10) && (@counter < 9)
      @frame.type = :strike
      calc_frame_scores
    end
  end

  def spare_or_open_frame?
    # second throw of a frame (not last frame)
    if (@counter < 9) && (@throws == 2)
      raise BowlingError if @scoring.last(2).inject(&:+) > 10
      @frame.type = @frame.score == 10 ? :spare : :open
      calc_frame_scores
    end
  end

  def last_frame?
    return if @counter != 9
    spare_or_open_frame_in_last_frame?
    bonus_round?
    if (@scoring.last(2).first != 10) && (@scoring.last(2).inject(&:+) > 10) && (@scoring.last(3)[0, 2].inject(&:+) != 10)
      raise BowlingError
    end
  end

  def spare_or_open_frame_in_last_frame?
    if (@throws == 2) && (@scoring.last(2).inject(&:+) < 10)
      @frame.type = :open
      calc_frame_scores
      @score += @scoring.last(2).inject(&:+)
      @status = :closed
    end
  end

  def bonus_round?
    if (@throws == 3) && (@scoring.last(3)[0, 2].inject(&:+) >= 10)
      if @frames[@counter - 1].type == :strike
        calc_frame_scores
        @score += @scoring.last
      else
        @score += @scoring.last(3).inject(&:+)
      end
      @frame.type = :end
      @status = :closed
    end
  end

  def two_past_frames_are_strikes?
    if (@counter - 2 >= 0) && (@frames[@counter - 1].type == :strike) && (@frames[@counter - 2].type == :strike)
      @score += if @frame.type == :strike
                  (10 + 10 + 10)
                else
                  (10 + 10 + @scoring.last(2).first)
                end
    end
  end

  def open_or_spare_and_strike_previous?
    # no strike frame but previous frame was a strike
    if (@counter - 1 >= 0) && (@frames[@counter - 1].type == :strike) && (@frame.type != :strike)
      @score += (10 + @scoring.last(2).inject(&:+) * 2)
    end
  end

  def past_frame_spare?
    # past frame was a spare
    if (@throws == 2) && (@counter - 1 >= 0) && (@frames[@counter - 1].type == :spare)
      @score += if @pins == 0
                  (10 + @scoring.last(2).inject(&:+) * 2)
                else
                  (10 + @scoring.last(2).first)
                end
    end
  end

  def calc_frame_scores
    two_past_frames_are_strikes?
    open_or_spare_and_strike_previous?
    past_frame_spare?

    # past frame was open
    if (@throws == 2) && (@frames[@counter - 1].type == :open)
      @score += @scoring.last(2).inject(&:+)
    end

    @throws = 0
    @counter += 1
  end
end

class Frame
  attr_accessor :score, :type

  def initialize
    @score = 0
    @type = :undefined
  end
end
