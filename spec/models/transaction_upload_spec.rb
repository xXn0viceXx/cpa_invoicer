require 'spec_helper'

describe TransactionUpload do
  let(:contents) do
    "T_index,DONOR_NO,RCPT_NO,TRAN_TYPE,DATE,AMOUNT,MOTIVE,THANK_LET,CATEGORY\n45017,103852,133541,R,9/17/2013,77,65,FALSE"
  end
  let(:cutoff_date) { Date.parse("2013-09-17") }
  let(:date) { Date.parse("2013-09-17") }
  let(:donor) { double.as_null_object }
  let(:io) { double(IO, read: contents) }
  let(:motive) { double.as_null_object }
  let(:transaction_attributes) do
    {receipt_number: "133541", donor_id: donor.id, motive_id: motive.id, receipt_date: date, amount: 77}
  end
  subject { described_class.new }

  before(:each) do
    Donor.stub(:where).and_return([donor])
    Motive.stub(:where).and_return([motive])
    Date.stub(:strptime).and_return(date)
    Transaction.stub(:where).and_return([])
  end

  it "creates a transaction for every record in the file" do
    Donor.should_receive(:where).with(donor_no: "103852").and_return([donor])
    Motive.should_receive(:where).with(number: "65").and_return([motive])
    Date.should_receive(:strptime).with("9/17/2013", "%m/%d/%Y").and_return(date)
    Transaction.should_receive(:create).with(transaction_attributes)

    subject.process(io, cutoff_date)
  end

  it "updates any existing transactions found in the file" do
    Transaction.should_receive(:where).with(receipt_number: "133541").and_return([transaction = double])
    transaction.should_receive(:update_attributes).with(transaction_attributes)

    subject.process(io, cutoff_date)
  end

  it "excludes any transactions that were created prior to the cutoff date" do
    Donor.should_not_receive(:where)
    Motive.should_not_receive(:where)
    Transaction.should_not_receive(:where)

    subject.process(io, Date.parse("2013-09-18"))
  end

  context "no matching donor found" do
    let(:contents) do
      "T_index,DONOR_NO,RCPT_NO,TRAN_TYPE,DATE,AMOUNT,MOTIVE,THANK_LET,CATEGORY\n45017,103852,133541,R,9/17/2013,77,65,FALSE\n45018,9999,133542,R,9/17/2013,77,65,FALSE"
    end
    let(:io) { double(IO, read: contents) }
    it "excludes the transaction" do
      Donor.should_receive(:where).with(donor_no: "103852").and_return([])
      Donor.should_receive(:where).with(donor_no: "9999").and_return([donor])

      subject.process(io, cutoff_date)
      subject.exclusions.should eql [{ receipt_number: "133541", reason: "no donor was found" }]
    end

    it "does not process an excluded transaction" do
      Donor.should_receive(:where).with(donor_no: "103852").and_return([])
      Donor.should_receive(:where).with(donor_no: "9999").and_return([donor])
      Transaction.should_not_receive(:create).with(hash_including(receipt_number: "133541"))
      Transaction.should_receive(:create).with(hash_including(receipt_number: "133542"))

      subject.process(io, cutoff_date)
    end
  end

  context "no matching motive found" do
    let(:contents) do
      "T_index,DONOR_NO,RCPT_NO,TRAN_TYPE,DATE,AMOUNT,MOTIVE,THANK_LET,CATEGORY\n45017,103852,133541,R,9/17/2013,77,15,FALSE\n45018,9999,133542,R,9/17/2013,77,65,FALSE"
    end
    let(:io) { double(IO, read: contents) }

    it "excludes the transaction" do
      Motive.should_receive(:where).with(number: "15").and_return([])
      Motive.should_receive(:where).with(number: "65").and_return([motive])

      subject.process(io, cutoff_date)
      subject.exclusions.should eql [{ receipt_number: "133541", reason: "no motive was found"}]
    end

    it "does not process an excluded transaction" do
      Motive.should_receive(:where).with(number: "15").and_return([])
      Motive.should_receive(:where).with(number: "65").and_return([motive])
      Transaction.should_not_receive(:create).with(hash_including(receipt_number: "133541"))
      Transaction.should_receive(:create).with(hash_including(receipt_number: "133542"))

      subject.process(io, cutoff_date)
    end
  end

end
