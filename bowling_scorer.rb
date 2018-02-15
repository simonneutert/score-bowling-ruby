module BowlingScorer
  private

  def score_pins
    if not_last_frame?
      score_frame
    else
      score_last_frame
    end
  end

  # Score results of frames except last frame
  def score_frame
    strike_frame?
    spare_or_open_frame?
  end

  # set Frame to Strike and score for Strike
  def strike_frame?
    if not_last_frame? && (@throws == 1) && (@pins == 10)
      @frame.type = :strike
      calc_frame_scores
    end
  end

  # set Frame to Spare or Open and score appropriately
  def spare_or_open_frame?
    if not_last_frame? && (@throws == 2)
      raise BowlingError if scores_of_n_last_frames(2) > 10
      @frame.type = if @frame.score == 10
                      :spare
                    else
                      :open
                    end
      calc_frame_scores
    end
  end

  # Score last frame separately because of possible bonus throw
  def score_last_frame
    spare_or_open_frame_in_last_frame?
    bonus_round?
    bonus_round_valid?
  end

  def spare_or_open_frame_in_last_frame?
    if (@throws == 2) && (scores_of_n_last_frames(2) < 10)
      @frame.type = :open
      calc_frame_scores { @score += scores_of_n_last_frames(2) }
      close_game
    end
  end

  def bonus_round?
    # if last frame was double strike or spare grant bonus throw
    if (@throws == 3) && (@scoring.last(3)[0, 2].inject(&:+) >= 10)
      if frame_before?(1, :strike)
        calc_frame_scores { @score += @pins }
      else
        @score += scores_of_n_last_frames(3)
      end
      # end game after three throws
      @frame.type = :end
      close_game
    end
  end

  def bonus_round_valid?
    if (first_of_current_frame != 10) && (scores_of_n_last_frames(2) > 10) && (@scoring.last(3)[0, 2].inject(&:+) != 10)
      raise BowlingError
    end
  end

  # calculate frame results regarding past scores / frames
  def calc_frame_scores
    score_two_past_frames_are_strikes?
    score_open_or_spare_and_prev_strike?
    score_prev_frame_spare?
    score_prev_frame_was_open?
    close_frame
    yield if block_given?
  end

  def score_two_past_frames_are_strikes?
    prev_double_strike = frame_before?(1, :strike) && frame_before?(2, :strike)
    if game_has_previous_frames?(2) && prev_double_strike
      @score += if @frame.type == :strike
                  (10 + 10 + 10)
                else
                  (10 + 10 + first_of_current_frame)
                end
    end
  end

  def score_open_or_spare_and_prev_strike?
    if game_has_previous_frames? && frame_before?(1, :strike) && (@frame.type != :strike)
      @score += (10 + scores_of_n_last_frames(2) * 2)
    end
  end

  def score_prev_frame_spare?
    if second_throw? && game_has_previous_frames? && frame_before?(1, :spare)
      @score += if @pins == 0
                  (10 + scores_of_n_last_frames(2) * 2)
                else
                  (10 + first_of_current_frame)
                end
    end
  end

  def score_prev_frame_was_open?
    if second_throw? && frame_before?(1, :open)
      @score += scores_of_n_last_frames(2)
    end
  end

  def close_frame
    @throws = 0
    @counter += 1
  end
end
