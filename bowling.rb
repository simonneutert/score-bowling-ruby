require_relative 'bowling_frame'
require_relative 'bowling_error'
require_relative 'bowling_helper'
require_relative 'bowling_scorer'

class Game
  include BowlingHelper
  include BowlingScorer

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

end
