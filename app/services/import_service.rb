class ImportService < ApplicationService
  BATCH_SIZE = 5000
  CSV_PATH = "tmp/data.csv"

  def call
    ts = Time.current.to_fs(:db)

    all_lines = File.foreach(CSV_PATH).lazy.drop(1)

    emails = all_lines.map { |line| line.split(",", 2).first }.uniq.sort

    emails.each_slice(BATCH_SIZE) do |batch|
      vals = batch.map { |e| "('#{e}', '#{ts}', '#{ts}')" }.join(", ")
      ActiveRecord::Base.connection.execute("INSERT IGNORE INTO users (email, created_at, updated_at) VALUES #{vals}")
    end

    users_by_email = User.pluck(:email, :id).to_h

    all_lines.each_slice(BATCH_SIZE) do |batch|
      insert_payments(batch, users_by_email, ts)
    end
  end

  private

  def insert_payments(raw_lines, users_by_email, ts)
    vals = raw_lines.map do |line|
      r = line.chomp.split(",")
      "('#{users_by_email[r[0]]}', '#{r[1]}', '#{r[2]}', '#{r[3] == "true" ? 1 : 0}', '#{ts}', '#{ts}')"
    end.join(", ")

    ActiveRecord::Base.connection.execute("INSERT INTO payments (user_id, amount, channel, anonymous, created_at, updated_at) VALUES #{vals}")
  end
end
