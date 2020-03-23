module Stellar
  class TransactionBuilder

    attr_reader :source_account, :sequence_number, :base_fee, :time_bounds, :time_bounds, :memo, :operations

    def initialize(
      source_account:, 
      sequence_number:, 
      base_fee: 100, 
      time_bounds: nil, 
      memo: nil
    )
      raise ArgumentError, "bad :source_account" unless source_account.is_a?(Stellar::KeyPair)
      raise ArgumentError, "bad :sequence_number" unless sequence_number.is_a?(Integer) && sequence_number > 0
      raise ArgumentError, "bad :time_bounds" unless time_bounds.is_a?(Stellar::TimeBounds) || time_bounds.nil?
      raise ArgumentError, "bad :base_fee" unless base_fee.is_a?(Integer) && base_fee >= 100

      @source_account = source_account
      @sequence_number = sequence_number
      @base_fee = base_fee
      @time_bounds = time_bounds
      @memo = self.make_memo(memo)
      @operations = Array.new
    end

    def build
      if @time_bounds.nil?
        raise "TransactionBuilder.time_bounds must be set during initialization or by calling set_timeout"
      elsif !@time_bounds.min_time.is_a?(Integer) or !@time_bounds.max_time.is_a?(Integer)
        raise "TimeBounds.min_time and max_time must be Integers"
      elsif @time_bounds.max_time != 0 and @time_bounds.min_time > @time_bounds.max_time
        raise "Timebounds.max_time must be greater than min_time"
      elsif @time_bounds.max_time != 0 and @time_bounds.max_time < Time.now.to_i
        raise "Timebounds.max_time must be in the future"
      end
      tx = Stellar::Transaction.new(
        source_account: @source_account.account_id,
        fee: @base_fee * @operations.length,
        seq_num: @sequence_number,
        time_bounds: @time_bounds,
        memo: @memo,
        operations: @operations,
        ext: Stellar::Transaction::Ext.new(0)
      )
      @sequence_number += 1
      tx
    end

    def add_operation(operation)
      raise ArgumentError, "bad operation" unless operation.is_a? Stellar::Operation
      @operations.push(operation)
      self
    end

    def clear_operations()
      @operations.clear
      self
    end

    def set_sequence_number(seq_num)
      raise ArgumentError, "bad sequence number" unless seq_num.is_a?(Integer) and seq_num > 0
      @sequence_number = seq_num
    end

    def set_timeout(timeout)
      if timeout < 0
        raise ArgumentError, "timeout cannot be negative"
      end

      if @time_bounds.nil?
        @time_bounds = Stellar::TimeBounds.new(min_time: 0, max_time: nil)
      end

      if timeout == 0
        @time_bounds.max_time = timeout
      else
        @time_bounds.max_time = Time.now.to_i + timeout
      end

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