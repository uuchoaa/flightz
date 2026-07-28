module GoogleFlights
  # Lazy token store for the anti-bot headers and query params the endpoint
  # demands. Resolution order: memory -> disk cache (fresh) -> browser
  # extraction -> stale cache -> the static HAR seed. Never raises; the
  # worst case is expired tokens and an HTTP error value upstream.
  class Tokens
    HEADER_KEYS = %w[X-Goog-BatchExecute-Bgr X-Goog-Ext-259736195-Jspb X-Browser-Validation].freeze
    QUERY_KEYS = %w[f.sid bl].freeze

    # Captured from a real session; expires, but keeps the client limping
    # when extraction is impossible (no Chrome around).
    SEED = {
      "f.sid" => "-4382590000827567880",
      "bl" => "boq_travel-frontend-flights-ui_20251209.02_p0",
      "X-Browser-Validation" => "AUXUCdutEJ+6gl6bYtz7E2kgIT4=",
      "X-Goog-Ext-259736195-Jspb" => '["pt-BR","BR","BRL",1,null,[180],null,null,7,[]]',
      "X-Goog-BatchExecute-Bgr" => '[";OCa4Jn7QAAZyDDXqUgxfKJeaEkPb4oAmADQBEArZ1KowcJzKpuSIzMqKFlnhpXZmbGosDbNd4JvlfQ_LFszqZoKtoiOZzeItDIkrf1KEHwAAAC9PAAAAAnUBB2MAQ5L-rDbhhGFqe1VStghsnP1nYgl7oNEKiaeCgyo4kjYAXA7TP_Ffa4WVe8CN0fe7xD5JfbXXwi3KNFvQYq7Nkuc780yEAzurOYUYkAx1lJxuZXmnqhcsEGmDQ5vXltWMPEb1uJww_kGjsF4js6tFGq_jrD7WSw1Lx3grbMcEKCLYW3UNs45Q0VjhYnDUBJsNjWLIwpW-hLXNf_eJQ1vcSkywS-0yY7FvRJees6ClGk_LPl87DbBxjdfy-k_3fJjE_jjoSyu4cNMqtYbq36huIGCC6OnzIlkHqyEy8OvvPYzShzCxR2-0YKmnYNB_Docp2S_eUIO5VKiyifM2qFxv5UjJ08QKWzGhGV9kI3zVxofuloPjLsnrKSO2CSJcNa-DSkROiJEMiAK07nJPUKVXhnBZYnNWh5xCHGvY1ZHh6q1pPW0Pq6Hgy13OH5zDec0S8afZhziVZpd9hOJmRLZPJ3HKFiwIK90hePDkOm-qOtbQ_2Ck_P8s9URzJTaQr-wDSXduHdL-628MopFdUyWL3duqPlIUnHk0N2-xImScrzlroCoYv40eQnwn3_BFzyN2kwLkO218QJNkO4Jk0AxYYFCargtvIc7gjqeufIvjEfSleKtcFOGbl3uDKF9E5KtuhXkkt1LSlTHDDS_LQjyGqwyso5uATCjvIMmD6tCbvyOqTRoWAsOtbl41VTRZQwwhoAMVpLL-cNoq-3gnyTK2mWoWPvhnlBgA0yaLzGguSl1YR5DADn1bHLIfPhA3o0BAtJbt0-nB2Ijc_G7ibw2UGiOEjYb74tFqU-T4Sea26n8NHAjmylDDVoFnpe2WZfyRcJpr-8J2Atu3yomD8B1fBTOud1IVVU0ebK5fzZ1Xg7zhlbAhMUaAUH5YOaTgosDmfQtQ81ejmkJGCAAMtWFnVCeyrq1Dgvcn36M3S8J9r8_WWxns3FHwcbAgR2hHcp1ApLtXMI7VylQ1DmrMHvDCXT-Ihs0mP_oJQHal7ySo7xC1SBqX1MFu5SouZUhVKsnu0yhVykdF7DGGmXlgjSIRcRe8wYMB4gOxnLSiv8c5eknuqcy2RPeMW3MdFyIxE5yOtXnPKApRpjmrHRPXOzNR4gKCRtDo6idg4FNeuHz_M1U516iOib_YVLBlpbYAGy-Ua-R3Wkh4fMsCPqJZQzYPaNVXo6qh5YXRhpigmamNGoFC4Q",null,null,151,38,null,null,0,"5"]'
    }.freeze

    def initialize(extractor: TokenExtractor.new, cache_path: default_cache_path, ttl: 24 * 3600, clock: Time)
      @extractor = extractor
      @cache_path = cache_path
      @ttl = ttl
      @clock = clock
      @mutex = Mutex.new
      @tokens = nil
      @refreshed_at = nil
    end

    def fetch(log: nil)
      @mutex.synchronize do
        if @tokens.nil?
          load_cache
          log&.call(@tokens ? :tokens_cache_hit : :tokens_cache_miss)
        end
        if @tokens.nil? || expired?
          log&.call(:tokens_refresh)
          refresh(log:)
        else
          log&.call(:tokens_fresh)
        end
        log&.call(:tokens_seed) if @tokens.nil?
        @tokens || SEED
      end
    end

    def refresh!
      @mutex.synchronize { refresh }
      fetch
    end

    private

    def expired?
      @refreshed_at.nil? || @clock.now.to_i - @refreshed_at > @ttl
    end

    def refresh(log: nil)
      extracted = @extractor.extract(log:)
      unless extracted # stale beats nothing
        log&.call(:tokens_extract_failed)
        return
      end

      @tokens = extracted.slice(*(HEADER_KEYS + QUERY_KEYS))
      @refreshed_at = @clock.now.to_i
      save_cache
    end

    def save_cache
      FileUtils.mkdir_p(File.dirname(@cache_path))
      File.write(@cache_path, JSON.generate({ tokens: @tokens, refreshed_at: @refreshed_at }))
    rescue SystemCallError
      nil
    end

    def load_cache
      return unless File.exist?(@cache_path)

      cached = JSON.parse(File.read(@cache_path))
      @tokens = cached["tokens"]
      @refreshed_at = cached["refreshed_at"]
    rescue JSON::ParserError, SystemCallError
      @tokens = nil
      @refreshed_at = nil
    end

    def default_cache_path
      base = defined?(Rails) ? Rails.root.join("tmp").to_s : "tmp"
      File.join(base, "google_flights_tokens.json")
    end
  end
end
