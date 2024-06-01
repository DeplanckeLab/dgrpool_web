class CompressionMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    if should_compress?(headers, env)
      headers['Content-Encoding'] = 'gzip'
      headers.delete('Content-Length')
      gzipped_body = compress(body)
      [status, headers, [gzipped_body]]
    else
      [status, headers, body]
    end
  end

  private

  def should_compress?(headers, env)
    # Add conditions here to determine if compression should be applied.
    # For example, based on Content-Type, file size, etc.
    true
  end

  def compress(body)
    compressed_body = StringIO.new
    gz = Zlib::GzipWriter.new(compressed_body)
    body.each { |part| gz.write(part) }
    gz.close
    compressed_body.string
  end
end
