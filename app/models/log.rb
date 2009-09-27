class Log < ActiveRecord::Base
  def append(data)
    update_attribute :log, [log, data].join
  end

  def last_line
    log.blank? ? "" : log.split("\n").last
  end
end
