class ServiceTokenService
  def self.get(service_slug)
    begin
      client.get(service_slug)
    rescue StandardError => e
      Rails.logger.warn "error getting service_slug #{service_slug} - #{e}"
    end
  end

  def self.client
    @client ||= Adapters::ServiceTokenCacheClient.new
  end
end
