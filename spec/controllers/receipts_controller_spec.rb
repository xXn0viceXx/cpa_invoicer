require 'spec_helper'

describe ReceiptsController do
  render_views
  let(:donor_1) { double(Donor) }
  let(:donor_2) { double(Donor) }
  let(:receipt) { double(Receipt) }

  let(:transaction_1) { double(Transaction, donor: donor_1) }
  let(:transaction_2) { double(Transaction, donor: donor_1) }
  let(:transaction_3) { double(Transaction, donor: donor_2) }
  let(:trr) { double(TransactionReceiptTransformer, persist_transformation: true) }
  before(:each) do
    Transaction.stub(:unallocated).and_return([transaction_1, transaction_2, transaction_3])
    TransactionReceiptTransformer.stub(:new).and_return(trr)
  end

  it "builds receipts from unallocated transactions" do
    trr.should_receive(:transform).with(donor_1, [transaction_1, transaction_2])
    trr.should_receive(:transform).with(donor_2, [transaction_3])

    post :build
  end

  it "persists any receipts that were created" do
    Transaction.stub(:unallocated).and_return([transaction_3])
    trr.stub(:transform).and_return(receipt)

    trr.should_receive(:persist_transformation).with(receipt, [transaction_3])
    
    post :build
  end
end