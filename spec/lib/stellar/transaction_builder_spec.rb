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
          time_bounds: 600
        )
      }.to raise_error(
        ArgumentError, "bad :time_bounds"
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
        time_bounds: Stellar::TimeBounds.new(min_time: 0, max_time: 600),
        base_fee: 200,
        memo: "My test memo"
      )
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
      expect { 
        tx = builder.add_operation(
          [:bump_sequence, 1]
        ).set_timeout(600).build()
      }.to raise_error(
        ArgumentError, "bad operation"
      )
    end

    it "raises error for time_bounds not set" do
      expect {
        tx = builder.add_operation(
          Stellar::Operation.bump_sequence({"bump_to": 1})
        ).build()
      }.to raise_error(
        RuntimeError, 
        "TransactionBuilder.time_bounds must be set during initialization or by calling set_timeout"
      )
    end

    it "raises an error for non-integer timebounds" do
      builder = Stellar::TransactionBuilder.new(
        source_account: key_pair,
        sequence_number: 1,
        time_bounds: Stellar::TimeBounds.new(min_time: "not", max_time: "integers")
      )
      expect {
        tx = builder.add_operation(
          Stellar::Operation.bump_sequence({"bump_to": 1})
        ).build()
      }.to raise_error(
        RuntimeError, "TimeBounds.min_time and max_time must be Integers"
      )
    end

    it "raises an error for bad TimeBounds range" do
      builder = Stellar::TransactionBuilder.new(
        source_account: key_pair,
        sequence_number: 1,
        time_bounds: Stellar::TimeBounds.new(min_time: Time.now.to_i + 10, max_time: Time.now.to_i)
      )
      expect {
        tx = builder.add_operation(
          Stellar::Operation.bump_sequence({"bump_to": 1})
        ).build()
      }.to raise_error(
        RuntimeError, "Timebounds.max_time must be greater than min_time"
      )
    end

    it "raises an error for max_time in past" do
      builder = Stellar::TransactionBuilder.new(
        source_account: key_pair,
        sequence_number: 1,
        time_bounds: Stellar::TimeBounds.new(min_time: 0, max_time: Time.now.to_i - 10)
      )
      expect {
        tx = builder.add_operation(
          Stellar::Operation.bump_sequence({"bump_to": 1})
        ).build()
      }.to raise_error(
        RuntimeError, "Timebounds.max_time must be in the future"
      )
    end

    it "allows max_time to be zero" do
      tx = builder.add_operation(
          Stellar::Operation.bump_sequence({"bump_to": 1})
      ).set_timeout(0).build()
      expect(builder.time_bounds.max_time).to eql(0)
    end

    it "creates transaction successfully" do
      bump_op = Stellar::Operation.bump_sequence({"bump_to": 1})
      builder.add_operation(
        Stellar::Operation.bump_sequence({"bump_to": 1})
      ).set_timeout(600).build()
      expect(builder.operations).to eql([bump_op])
    end
  end
end