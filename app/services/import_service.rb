class ImportService < ApplicationService
  def call
    rows = CSV.read("tmp/data.csv", headers: true)
    emails = rows.map { |r| r["email"] }.uniq

    users_by_email = User.where(email: emails).index_by(&:email)

    # Create users that are not in the database yet
    missing_emails = emails - users_by_email.keys
    User.insert_all(missing_emails.map { |email| { email: email } })
    users_by_email.merge!(User.where(email: missing_emails).index_by(&:email))

    payments = rows.map do |row|
      { user_id: users_by_email[row["email"]].id, amount: row["amount"], channel: row["channel"], anonymous: row["anonymous"] }
    end

    Payment.insert_all(payments)
  end
end
