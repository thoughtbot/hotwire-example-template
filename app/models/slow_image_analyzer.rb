class SlowImageAnalyzer < ActiveStorage::Analyzer::ImageAnalyzer::Vips
  def metadata
    sleep 5

    super
  end
end
