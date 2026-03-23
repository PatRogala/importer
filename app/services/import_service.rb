class ImportService < ApplicationService
  BATCH_SIZE = 5000
  WORKERS    = 4
  CSV_PATH   = "tmp/data.csv"

  def call
    ts = Time.current.to_fs(:db)

    all_lines = File.foreach(CSV_PATH).drop(1)
    emails = all_lines.map { |line| line.split(",", 2).first }.uniq.sort

    parallel_insert(emails.each_slice(BATCH_SIZE)) do |batch, conn|
      vals = batch.map { |e| "(#{conn.quote(e)}, '#{ts}', '#{ts}')" }.join(", ")
      conn.execute("INSERT IGNORE INTO users (email, created_at, updated_at) VALUES #{vals}")
    end

    users_by_email = User.pluck(:email, :id).to_h
    payment_batches = File.foreach(CSV_PATH).lazy.drop(1).each_slice(BATCH_SIZE)
    parallel_insert(payment_batches) do |batch, conn|
      insert_payments(batch, users_by_email, ts, conn)
    end
  end

  private

  def parallel_insert(batches)
    queue = Queue.new
    batches.each { |b| queue << b }

    threads = WORKERS.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.execute("SET FOREIGN_KEY_CHECKS=0")
          conn.transaction do
            loop do
              batch = queue.pop(true)
              yield batch, conn
            rescue ThreadError
              break
            end
          end
        end
      end
    end
    threads.each(&:join)
  end

  def insert_payments(raw_lines, users_by_email, ts, conn)
    vals = raw_lines.map do |line|
      r = line.chomp.split(",")
      "(#{users_by_email[r[0]].to_i}, #{r[1].to_f}, #{conn.quote(r[2])}, #{r[3] == "true" ? 1 : 0}, '#{ts}', '#{ts}')"
    end.join(", ")

    conn.execute("INSERT INTO payments (user_id, amount, channel, anonymous, created_at, updated_at) VALUES #{vals}")
  end
end
