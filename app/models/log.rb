class Log < ActiveRecord::Base
  def last_line
    log.split("\n").last
  end
end
