# Backport https://github.com/rails/rails/commit/294c2710620871a691e4ca5fefb5e5ace279195d

ActiveSupport.on_load :active_storage_blob do
  after_update :touch_attachment_records

  def touch_attachment_records
    attachments.includes(:record).each do |attachment|
      attachment.touch
    end
  end
end
