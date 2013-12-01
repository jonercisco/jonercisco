module TimeLineable
  extend ActiveSupport::Concern

  included do
    validates_presence_of :started_at # , :if => :has_previous?
    validates_presence_of :stopped_at, :if => :has_followings?

    scope :at,      lambda { |at| where("? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?)", at, at, at) }
    scope :after,   lambda { |at| where("COALESCE(started_at, ?) > ?", at, at) }
    scope :before,  lambda { |at| where("COALESCE(started_at, ?) < ?", at, at) }
    scope :current, -> { at(Time.now) }

    before_validation do
      if following = siblings.after(self.started_at).order(:started_at).first
        self.stopped_at = following.started_at
      else
        unless siblings.any?
          self.started_at ||= Time.new(1, 1, 1, 0, 0, 0, "+00:00")
        end
        self.stopped_at = nil
      end
    end

    before_update do
      old = old_record
      if old.started_at != self.started_at and previous = old.previous
        previous.update_column(:stopped_at, old.stopped_at)
      end
    end

    after_save do
      if previous = siblings.before(self.started_at).reorder("started_at DESC").first || siblings.where(started_at: nil).first
        previous.update_column(:stopped_at, self.started_at)
      end
    end

    after_destroy do
      if previous = self.previous
        self.previous.update_column(:stopped_at, self.stopped_at)
      end
    end
  end

  def previous
    return nil unless self.started_at
    return siblings.find_by(stopped_at: self.started_at)
  end

  def following
    return nil unless self.stopped_at
    return siblings.find_by(started_at: self.stopped_at)
  end

  def has_previous?
    siblings.before(self.started_at).any?
  end

  def has_followings?
    siblings.after(self.started_at).any?
  end

  private

  def siblings
    raise NotImplementedError, "Private method :siblings must be implemented"
  end

end
