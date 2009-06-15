class Archive
  class << self
    def create(to_archive, archive_path)
      `tar --file=#{archive_path} -czv #{to_archive}`
    end
  end
end

