class ImportService < ApplicationService
  BATCH_SIZE = 5000
  WORKERS = 4
  USER_INSERT_MUTEX = Mutex.new

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
    ts = Time.current.to_fs(:db)

    rows = raw_lines.map { |line| line.chomp.split(",") }
    emails = rows.map { |r| r[0] }.uniq
    emails.sort! # Gap Lock Deadlocks

    placeholders = ([ "(?, ?, ?)" ] * emails.size).join(", ")
    values = emails.flat_map { |e| [ e, ts, ts ] }
    sql = ActiveRecord::Base.sanitize_sql(
      [ "INSERT IGNORE INTO users (email, created_at, updated_at) VALUES #{placeholders}", *values ]
    )
    USER_INSERT_MUTEX.synchronize do
      ActiveRecord::Base.connection.execute(sql)
    end

    users_by_email = User.where(email: emails).pluck(:email, :id).to_h

    payment_rows = rows.map { |row| [ users_by_email[row[0]], row[1], row[2], row[3] == "true" ? 1 : 0, ts, ts ] }
    payment_rows.sort_by! { |r| r[0] } # Gap Lock Deadlocks

    placeholders = ([ "(?, ?, ?, ?, ?, ?)" ] * payment_rows.size).join(", ")
    values = payment_rows.flatten
    sql = ActiveRecord::Base.sanitize_sql(
      [ "INSERT INTO payments (user_id, amount, channel, anonymous, created_at, updated_at) VALUES #{placeholders}", *values ]
    )
    ActiveRecord::Base.connection.execute(sql)
  end
end
