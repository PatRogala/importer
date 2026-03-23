class ImportService < ApplicationService
  def call
    payments = []

    CSV.foreach("tmp/data.csv", headers: true) do |row|
      user = User.find_or_create_by(email: row["email"])
      payments << { user_id: user.id, amount: row["amount"], channel: row["channel"], anonymous: row["anonymous"] }
    end

    Payment.insert_all(payments)
  end
end
