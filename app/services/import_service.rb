class ImportService < ApplicationService
  BATCH_SIZE = 5000
  WORKERS = 4

  def call
    queue = SizedQueue.new(WORKERS * 2)

    producer = Thread.new do
      File.foreach("tmp/data.csv").lazy.drop(1).each_slice(BATCH_SIZE) do |batch|
        queue << batch
      end
      WORKERS.times { queue << nil }
    end

    consumers = WORKERS.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          while (batch = queue.pop)
            process_batch(batch)
          end
        end
      end
    end

    producer.join
    consumers.each(&:join)
  end

  private

  def process_batch(raw_lines)
    now = Time.current

    rows = raw_lines.map { |line| line.chomp.split(",") }
    emails = rows.map { |r| r[0] }.uniq

    # Gap Lock Deadlocks
    emails.sort!

    ActiveRecord::Base.transaction do
      User.insert_all(emails.map { |e| { email: e, created_at: now, updated_at: now } })

      users_by_email = User.where(email: emails).pluck(:email, :id).to_h

      payment_payloads = rows.map do |row|
        {
          user_id: users_by_email[row[0]],
          amount: row[1],
          channel: row[2],
          anonymous: row[3],
          created_at: now,
          updated_at: now
        }
      end

      # Gap Lock Deadlocks
      payment_payloads.sort_by! { |p| p[:user_id] }

      Payment.insert_all(payment_payloads)
    end
  end
end
