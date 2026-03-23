class ImportService < ApplicationService
  BATCH_SIZE = 2000

  def call
    CSV.foreach("tmp/data.csv", headers: true).each_slice(BATCH_SIZE) do |batch|
      process_batch(batch)
    end
  end

  private

  def process_batch(rows)
    emails = rows.map { |r| r["email"] }.uniq

    users_by_email = User.where(email: emails).index_by(&:email)

    missing_emails = emails - users_by_email.keys
    if missing_emails.any?
      User.insert_all(missing_emails.map { |e| { email: e } })
      users_by_email.merge!(User.where(email: missing_emails).index_by(&:email))
    end

    Payment.insert_all(
      rows.map do |row|
        {
          user_id: users_by_email[row["email"]].id,
          amount: row["amount"],
          channel: row["channel"],
          anonymous: row["anonymous"]
        }
      end
    )
  end
end
