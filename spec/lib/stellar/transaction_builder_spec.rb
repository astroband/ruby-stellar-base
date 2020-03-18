require "spec_helper"

describe Stellar::TransactionBuilder do
  let(:key_pair){ Stellar::KeyPair.random }

  describe ".initialize" do
    it "bad source_account" do
      expect { 
        Stellar::TransactionBuilder.new(
          source_account: key_pair.account_id,
          sequence_number: 1
        )
      }.to raise_error(
        ArgumentError, "bad :source_account"
      )
    end
    it "bad sequence_number" do
      expect {
        Stellar::TransactionBuilder.new(
          source_account: key_pair,
          sequence_number: 0
        )
      }.to raise_error(
        ArgumentError, "bad :sequence_number"
      )
    end
    it "bad timeout" do
      expect {
        Stellar::TransactionBuilder.new(
          source_account: key_pair,
          sequence_number: 1,
          timeout: Stellar::TimeBounds.new(min_time: 0, max_time: 0)
        )
      }.to raise_error(
        ArgumentError, "bad :timeout"
      )
    end
    it "bad base_fee" do
      expect {
        Stellar::TransactionBuilder.new(
          source_account: key_pair,
          sequence_number: 1,
          base_fee: 0
        )
      }.to raise_error(
        ArgumentError, "bad :base_fee"
      )
    end
    it "bad memo" do
      expect {
        Stellar::TransactionBuilder.new(
          source_account: key_pair,
          sequence_number: 1,
          memo: {"data" => "Testing bad memo"}
        )
      }.to raise_error(
        ArgumentError, "bad :memo"
      )
    end
    it "success" do
      builder = Stellar::TransactionBuilder.new(
        source_account: key_pair,
        sequence_number: 1,
        timeout: 600,
        base_fee: 200,
        memo: "My test memo"
      )
      expect(builder.time_bounds).to be_kind_of(Stellar::TimeBounds)
      expect(builder.memo).to eql(Stellar::Memo.new(:memo_text, "My test memo"))
    end
  end

  describe ".build" do
    builder = nil

    before(:each) do
      builder = Stellar::TransactionBuilder.new(
        source_account: key_pair,
        sequence_number: 1
      )
    end

    it "bad operation" do
      expect { builder.add_operation([:bump_sequence, 1]).build() }.to raise_error(
        ArgumentError, "bad operation"
      )
    end

    it "creates transaction successfully" do
      bump_op = Stellar::Operation.bump_sequence({"bump_to": 1})
      tx = builder.add_operation(
        Stellar::Operation.bump_sequence({"bump_to": 1})
      ).build()
      expect(tx.operations).to eql([bump_op])
    end
  end
end