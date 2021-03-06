require "csv"

class TransactionUpload
  include ActiveModel::Model
  attr_reader :exclusions
  def initialize
    @exclusions = []
  end
  def process(io, cutoff_date)
    CSV.parse(io.read, headers: true).each do |rec|
      date = Date.strptime(rec["DATE"], "%m/%d/%Y")
      next unless date >= cutoff_date

      unless donor = Donor.where(donor_no: rec["DONOR_NO"]).first
        @exclusions << { receipt_number: rec["RCPT_NO"], reason: 'no donor was found' }
        next
      end
      unless motive = Motive.where(number: rec["MOTIVE"]).first
        @exclusions << { receipt_number: rec["RCPT_NO"], reason: 'no motive was found' }
        next
      end

      if transaction = Transaction.where(receipt_number: rec["RCPT_NO"]).first
        transaction.update_attributes(receipt_number: rec["RCPT_NO"], donor_id: donor.id, motive_id: motive.id, receipt_date: date, amount: rec["AMOUNT"].to_i)
      else
        Transaction.create(receipt_number: rec["RCPT_NO"], donor_id: donor.id, motive_id: motive.id, receipt_date: date, amount: rec["AMOUNT"].to_i)
      end
    end
  end
end
