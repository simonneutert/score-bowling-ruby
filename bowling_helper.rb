module BowlingHelper
  private

  def scores_of_n_last_frames(x)
    @scoring.last(x).inject(&:+)
  end

  def first_of_current_frame
    @scoring.last(2).first
  end

  def game_has_previous_frames?(x = 1)
    @counter - x >= 0
  end

  def not_last_frame?
    @counter < 9
  end

  def frame_before?(n, type)
    @frames[@counter - n].type == type
  end

  def second_throw?
    @throws == 2
  end

  def close_game
    @status = :closed
  end
end
