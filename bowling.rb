class Game
  attr_accessor :score, :counter, :frames, :throws, :scoring, :frame, :status

  def initialize
    @score = 0
    @counter = 0
    @throws = 0
    @frames = (0..9).to_a.map { |_e| Frame.new }
    @scoring = []
    @status = :open
  end

  # logic for counting
  def roll(pins)
    raise BowlingError if (pins < 0) || (pins > 10)
    raise BowlingError if @status == :closed

    @scoring << pins
    @throws += 1
    @frame = @frames[@counter]

    # throw sets frame score
    @frame.score += pins

    # strike is thrown (not in last frame)
    if (@throws == 1) && (pins == 10) && (@counter < 9)
      @frame.type = :strike
      calc_frame_scores pins
    end

    # second throw of a frame (not last frame)
    if (@counter < 9) && (@throws == 2)
      raise BowlingError if @scoring.last(2).inject(&:+) > 10
      @frame.type = @frame.score == 10 ? :spare : :open
      calc_frame_scores pins
    end

    if @counter == 9
      if (@throws == 2) && (@scoring.last(2).inject(&:+) < 10)
        @frame.type = :open
        calc_frame_scores pins
        @score += @scoring.last(2).inject(&:+)
        @status = :closed
      elsif (@throws == 3) && (@scoring.last(3)[0, 2].inject(&:+) >= 10)
        if @frames[@counter - 1].type == :strike
          calc_frame_scores pins
          @score += @scoring.last
        else
          @score += @scoring.last(3).inject(&:+)
        end
        @frame.type = :end
        @status = :closed
      end
      if (@scoring.last(2).first != 10) && (@scoring.last(2).inject(&:+) > 10) && (@scoring.last(3)[0, 2].inject(&:+) != 10)
        raise BowlingError
      end
    end
  end

  def score
    if @frames.map(&:type).all? { |e| e != :undefined }
      @score
    else
      raise BowlingError
    end
  end

  private

  def calc_frame_scores(pins)
    # two past frames are strikes
    if (@counter - 2 >= 0) && (@frames[@counter - 1].type == :strike) && (@frames[@counter - 2].type == :strike)
      @score += if @frame.type == :strike
                  (10 + 10 + 10)
                else
                  (10 + 10 + @scoring.last(2).first)
                end
    end

    # no strike frame but previous frame was a strike
    if (@counter - 1 >= 0) && (@frames[@counter - 1].type == :strike) && (@frame.type != :strike)
      @score += (10 + @scoring.last(2).inject(&:+) * 2)
    end

    # past frame was a spare
    if (@throws == 2) && (@counter - 1 >= 0) && (@frames[@counter - 1].type == :spare)
      @score += if pins == 0
                  (10 + @scoring.last(2).inject(&:+) * 2)
                else
                  (10 + @scoring.last(2).first)
                end
    end

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

class BowlingError < StandardError
end
