class ImportService < ApplicationService
  BATCH_SIZE = 5000

  def call
    File.foreach("tmp/data.csv").lazy.drop(1).each_slice(BATCH_SIZE) do |batch|
      process_batch(batch)
    end
  end

  private

  def process_batch(raw_lines)
    now = Time.current

    rows = raw_lines.map { |line| line.chomp.split(",") }
    emails = rows.map { |r| r[0] }.uniq

    ActiveRecord::Base.transaction do
      User.insert_all(emails.map { |e| { email: e, created_at: now, updated_at: now } })

      users_by_email = User.where(email: emails).pluck(:email, :id).to_h

      Payment.insert_all(
        rows.map do |row|
          {
            user_id: users_by_email[row[0]],
            amount: row[1],
            channel: row[2],
            anonymous: row[3],
            created_at: now,
            updated_at: now
          }
        end
      )
    end
  end
end
