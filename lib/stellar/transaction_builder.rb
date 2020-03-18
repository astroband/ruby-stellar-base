module Stellar
  class TransactionBuilder

    attr_reader :source_account, :sequence_number, :base_fee, :timeout, :time_bounds, :memo, :operations

    def initialize(
      source_account:, 
      sequence_number:, 
      base_fee: 100, 
      timeout: 0, 
      memo: nil
    )
      raise ArgumentError, "bad :source_account" unless source_account.is_a?(Stellar::KeyPair)
      raise ArgumentError, "bad :sequence_number" unless sequence_number.is_a?(Integer) && sequence_number > 0
      raise ArgumentError, "bad :timeout" unless timeout.is_a?(Integer) && timeout >= 0
      raise ArgumentError, "bad :base_fee" unless base_fee.is_a?(Integer) && base_fee >= 100

      @timeout = timeout
      now = Time.now.to_i
      max_time = timeout != 0 ? now + timeout : timeout

      @source_account = source_account
      @sequence_number = sequence_number
      @base_fee = base_fee
      @time_bounds = Stellar::TimeBounds.new(min_time: now, max_time: max_time)
      @memo = self.make_memo(memo)
      @operations = Array.new
    end

    def build
      Stellar::Transaction.new(
        source_account: @source_account.account_id,
        fee: @base_fee * @operations.length,
        seq_num: @sequence_number,
        time_bounds: @time_bounds,
        memo: @memo,
        operations: @operations,
        ext: Stellar::Transaction::Ext.new(0)
      )
    end

    def add_operation(operation)
      raise ArgumentError, "bad operation" unless operation.is_a? Stellar::Operation
      @operations.push(operation)
      self
    end

    def make_memo(memo)
      case memo
      when Stellar::Memo ;
        memo
      when nil ;
        Memo.new(:memo_none)
      when Integer ;
        Memo.new(:memo_id, memo)
      when String ;
        Memo.new(:memo_text, memo)
      when Array ;
        t, val = *memo
        Memo.new(:"memo_#{t}", val)
      else
        raise ArgumentError, "bad :memo"
      end
    end

  end
end