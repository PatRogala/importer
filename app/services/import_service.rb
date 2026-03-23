class ImportService < ApplicationService
  BATCH_SIZE = 5000

  def call
    CSV.foreach("tmp/data.csv", headers: true).lazy.each_slice(BATCH_SIZE) do |batch|
      process_batch(batch)
    end
  end

  private

  def process_batch(rows)
    now = Time.current
    emails = rows.map { |r| r["email"] }.uniq

    ActiveRecord::Base.transaction do
      User.insert_all(emails.map { |e| { email: e, created_at: now, updated_at: now } })

      users_by_email = User.where(email: emails).index_by(&:email)

      Payment.insert_all(
        rows.map do |row|
          {
            user_id: users_by_email[row["email"]].id,
            amount: row["amount"],
            channel: row["channel"],
            anonymous: row["anonymous"],
            created_at: now,
            updated_at: now
          }
        end
      )
    end
  end
end
