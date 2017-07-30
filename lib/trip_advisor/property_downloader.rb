module TripAdvisor
  # Performs downloading of the property data files from the TripAdvisor SFTP
  # server.
  class PropertyDownloader
    attr_reader :host, :username, :password

    def initialize(sftp_details:)
      @host = sftp_details.host
      @username = sftp_details.username
      @password = sftp_details.password
    end

    # Connects to the TripAdvisor SFTP server and downloads the gzipped listings
    # delta file.
    # Returns the local path of the downloaded file.
    def download_delta(date: Date.today)
      mk_local_delta_dir
      delta_fn = delta_filename(date)
      local = local_delta_path(delta_fn)

      Net::SFTP.start(host, username, password: password) do |sftp|
        sftp.download!(remote_delta_path(delta_fn), local)
      end
      local
    end

    private

    def delta_filename(date)
      "listings_delta_#{date.strftime('%Y%m%d')}.tar.gz"
    end

    def mk_local_delta_dir
      return if FileTest.exist?(local_delta_directory)
      FileUtils.mkdir_p(local_delta_directory)
    end

    def local_delta_path(filename)
      File.join(local_delta_directory, filename)
    end

    def local_delta_directory
      File.join(Rails.root, 'trip_advisor', 'listings', 'delta')
    end

    def remote_delta_path(filename)
      '/drop/listings/delta/' + filename
    end
  end
end
