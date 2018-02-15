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
    in_last_frame?
  end

  def strike_not_in_last_frame?
    if (@throws == 1) && (@pins == 10) && not_last_frame?
      @frame.type = :strike
      calc_frame_scores
      return true
    else
      return false
    end
  end

  def not_last_frame?
    @counter < 9
  end

  def spare_or_open_frame?
    if not_last_frame? && (@throws == 2)
      raise BowlingError if scores_of_last(2) > 10
      @frame.type = @frame.score == 10 ? :spare : :open
      calc_frame_scores
      return true
    else
      return false
    end
  end

  def in_last_frame?
    if @counter == 9
      spare_or_open_frame_in_last_frame?
      bonus_round?
      if (first_of_current_frame != 10) && (scores_of_last(2) > 10) && (@scoring.last(3)[0, 2].inject(&:+) != 10)
        raise BowlingError
      end
      return true
    else
      return false
    end
  end

  def spare_or_open_frame_in_last_frame?
    if (@throws == 2) && (scores_of_last(2) < 10)
      @frame.type = :open
      calc_frame_scores
      @score += @scoring.last(2).inject(&:+)
      @status = :closed
      return true
    else
      return false
    end
  end

  def bonus_round?
    if (@throws == 3) && (@scoring.last(3)[0, 2].inject(&:+) >= 10)
      if @frames[@counter - 1].type == :strike
        calc_frame_scores
        @score += @scoring.last
      else
        @score += scores_of_last(3)
      end
      @frame.type = :end
      @status = :closed
      return true
    else
      return false
    end
  end


  def two_past_frames_are_strikes?
    if game_has_previous_frames?(2) && (@frames[@counter - 1].type == :strike) && (@frames[@counter - 2].type == :strike)
      if @frame.type == :strike
        @score += (10 + 10 + 10)
      else
        @score += (10 + 10 + first_of_current_frame)
      end
      return true
    else
      return false
    end
  end

  def open_or_spare_and_strike_previous?
    if game_has_previous_frames? && (@frames[@counter - 1].type == :strike) && (@frame.type != :strike)
      @score += (10 + scores_of_last(2) * 2)
      return true
    else
      return false
    end
  end

  def past_frame_spare?
    # past frame was a spare
    if (@throws == 2) && game_has_previous_frames? && (@frames[@counter - 1].type == :spare)
      @score += @pins == 0 ? (10 + scores_of_last(2) * 2) : (10 + first_of_current_frame)
      return true
    else
      return false
    end
  end

  def past_frame_was_open?
    # past frame was open
    if (@throws == 2) && (@frames[@counter - 1].type == :open)
      @score += scores_of_last(2)
      return true
    else
      return false
    end
  end

  def calc_frame_scores
    two_past_frames_are_strikes?
    open_or_spare_and_strike_previous?
    past_frame_spare?
    past_frame_was_open?
    close_frame
  end

  def close_frame
    @throws = 0
    @counter += 1
  end

  def scores_of_last(x)
    if @scoring.size >= x
      @scoring.last(x).inject(&:+)
    else
      raise BowlingError
    end
  end

  def first_of_current_frame
    @scoring.last(2).first
  end

  def game_has_previous_frames?(x=1)
    @counter - x >= 0
  end

end

class Frame
  attr_accessor :score, :type

  def initialize
    @score = 0
    @type = :undefined
  end
end
