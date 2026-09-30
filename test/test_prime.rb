# frozen_string_literal: false
require 'test/unit'
require 'prime'
require 'timeout'

class TestPrime < Test::Unit::TestCase
  # The first 100 prime numbers
  PRIMES = [
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37,
    41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83,
    89, 97, 101, 103, 107, 109, 113, 127, 131,
    137, 139, 149, 151, 157, 163, 167, 173, 179,
    181, 191, 193, 197, 199, 211, 223, 227, 229,
    233, 239, 241, 251, 257, 263, 269, 271, 277,
    281, 283, 293, 307, 311, 313, 317, 331, 337,
    347, 349, 353, 359, 367, 373, 379, 383, 389,
    397, 401, 409, 419, 421, 431, 433, 439, 443,
    449, 457, 461, 463, 467, 479, 487, 491, 499,
    503, 509, 521, 523, 541,
  ]
  def test_each
    primes = []
    Prime.each do |p|
      break if p > 541
      primes << p
    end
    assert_equal PRIMES, primes
  end

  def test_include?
    assert_equal(false, Prime.include?(nil))
    assert_equal(true, Prime.include?(3))
    assert_equal(false, Prime.include?(4))
    assert_equal(true, Prime.include?(Enumerable))
    assert_equal(false, Prime.include?(Comparable))
  end

  def test_integer_each_prime
    primes = []
    Integer.each_prime(1000) do |p|
      break if p > 541
      primes << p
    end
    assert_equal PRIMES, primes
  end

  def test_each_by_prime_number_theorem
    3.upto(15) do |i|
      max = 2**i
      primes = []
      Prime.each do |p|
        break if p >= max
        primes << p
      end

      # Prime number theorem
      assert_operator primes.length, :>=, max/Math.log(max)
      delta = 0.05
      li = (2..max).step(delta).inject(0){|sum,x| sum + delta/Math.log(x)}
      assert_operator primes.length, :<=, li
    end
  end

  def test_each_without_block
    enum = Prime.each
    assert_respond_to(enum, :each)
    assert_kind_of(Enumerable, enum)
    assert_respond_to(enum, :with_index)
    assert_respond_to(enum, :next)
    assert_respond_to(enum, :succ)
    assert_respond_to(enum, :rewind)
  end

  def test_instance_without_block
    enum = Prime.instance.each
    assert_respond_to(enum, :each)
    assert_kind_of(Enumerable, enum)
    assert_respond_to(enum, :with_index)
    assert_respond_to(enum, :next)
    assert_respond_to(enum, :succ)
    assert_respond_to(enum, :rewind)
  end

  def test_new
    assert_raise(NoMethodError) { Prime.new }
  end

  def test_enumerator_succ
    enum = Prime.each
    assert_equal PRIMES[0, 50], 50.times.map{ enum.succ }
    assert_equal PRIMES[50, 50], 50.times.map{ enum.succ }
    enum.rewind
    assert_equal PRIMES[0, 100], 100.times.map{ enum.succ }
  end

  def test_enumerator_with_index
    enum = Prime.each
    last = -1
    enum.with_index do |p,i|
      break if i >= 100
      assert_equal last+1, i
      assert_equal PRIMES[i], p
      last = i
    end
  end

  def test_enumerator_with_index_with_offset
    enum = Prime.each
    last = 5-1
    enum.with_index(5).each do |p,i|
      break if i >= 100+5
      assert_equal last+1, i
      assert_equal PRIMES[i-5], p
      last = i
    end
  end

  def test_enumerator_with_object
    object = Object.new
    enum = Prime.each
    enum.with_object(object).each do |p, o|
      assert_equal object, o
      break
    end
  end

  def test_enumerator_size
    enum = Prime.each
    assert_equal Float::INFINITY, enum.size
    assert_equal Float::INFINITY, enum.with_object(nil).size
    assert_equal Float::INFINITY, enum.with_index(42).size
  end

  def test_default_instance_does_not_have_compatibility_methods
    assert_not_respond_to(Prime.instance, :succ)
    assert_not_respond_to(Prime.instance, :next)
  end

  def test_prime_each_basic_argument_checking
    assert_raise(ArgumentError) { Prime.prime?(1,2) }
    assert_raise(ArgumentError) { Prime.prime?(1.2) }
  end

  def test_prime?
    assert_equal Prime.prime?(1), false
    assert_equal Prime.prime?(2), true
    assert_equal Prime.prime?(4), false
  end

  class TestPseudoPrimeGenerator < Test::Unit::TestCase
    def test_upper_bound
      pseudo_prime_generator = Prime::PseudoPrimeGenerator.new(42)
      assert_equal pseudo_prime_generator.upper_bound, 42
    end

    def test_succ
      pseudo_prime_generator = Prime::PseudoPrimeGenerator.new(42)
      assert_raise(NotImplementedError) { pseudo_prime_generator.succ }
    end

    def test_next
      pseudo_prime_generator = Prime::PseudoPrimeGenerator.new(42)
      assert_raise(NotImplementedError) { pseudo_prime_generator.next }
    end

    def test_rewind
      pseudo_prime_generator = Prime::PseudoPrimeGenerator.new(42)
      assert_raise(NotImplementedError) { pseudo_prime_generator.rewind }
    end
  end

  class TestTrialDivisionGenerator < Test::Unit::TestCase
    # The first 100 prime numbers
    PRIMES = [
      2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37,
      41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83,
      89, 97, 101, 103, 107, 109, 113, 127, 131,
      137, 139, 149, 151, 157, 163, 167, 173, 179,
      181, 191, 193, 197, 199, 211, 223, 227, 229,
      233, 239, 241, 251, 257, 263, 269, 271, 277,
      281, 283, 293, 307, 311, 313, 317, 331, 337,
      347, 349, 353, 359, 367, 373, 379, 383, 389,
      397, 401, 409, 419, 421, 431, 433, 439, 443,
      449, 457, 461, 463, 467, 479, 487, 491, 499,
      503, 509, 521, 523, 541,
    ]

    def test_each
      primes = []
      Prime.each(nil, Prime::TrialDivisionGenerator.new) do |p|
        break if p > 541
        primes << p
      end
      assert_equal PRIMES, primes
    end

    def test_rewind
      generator = Prime::TrialDivisionGenerator.new
      assert_equal generator.next, 2
      assert_equal generator.next, 3
      generator.rewind
      assert_equal generator.next, 2
    end
  end

  class TestGenerator23 < Test::Unit::TestCase
    def test_rewind
      generator = Prime::Generator23.new
      assert_equal generator.next, 2
      assert_equal generator.next, 3
      generator.rewind
      assert_equal generator.next, 2
    end
  end

  class TestDiscreteLog < Test::Unit::TestCase
    # Full power table of g modulo p: { g**x % p => x }, whose size is
    # the multiplicative order of g.  Independent reference
    # implementation used to cross-check Prime.discrete_log.
    def power_table(g, p)
      table = {}
      power = 1
      x = 0
      until table.key?(power)
        table[power] = x
        power = power * g % p
        x += 1
      end
      table
    end

    def test_non_primitive_root_returns_class_mod_order
      # 3 has order 3 modulo 13; it is not a primitive root.
      assert_equal [2, 3], Prime.discrete_log(3, 9, 13)
      assert_equal [1, 3], Prime.discrete_log(3, 3, 13)
    end

    def test_zero_exponent
      assert_equal [0, 11], Prime.discrete_log(2, 1, 23) # ord(2) == 11
      assert_equal [0, 1], Prime.discrete_log(1, 1, 23)
      assert_equal [0, 1], Prime.discrete_log(1, 1, 2)
    end

    def test_no_solution_returns_nil
      # 2 is not in {1, 3, 9}, the subgroup generated by 3 modulo 13.
      assert_nil Prime.discrete_log(3, 2, 13)
      assert_nil Prime.discrete_log(1, 2, 23)
    end

    def test_order_with_high_prime_power
      # 2 has order 3**5 == 243 modulo 487.
      assert_equal [200, 243], Prime.discrete_log(2, 2.pow(200, 487), 487)
      assert_equal [242, 243], Prime.discrete_log(2, 2.pow(242, 487), 487)
      assert_equal [0, 243], Prime.discrete_log(2, 1, 487)
    end

    def test_crt_merging_over_composite_order
      # 3 is a primitive root modulo 2311; 2310 == 2*3*5*7*11.
      assert_equal [1234, 2310], Prime.discrete_log(3, 3.pow(1234, 2311), 2311)
      assert_equal [2309, 2310], Prime.discrete_log(3, 3.pow(2309, 2311), 2311)
    end

    def test_exhaustive_cross_check_with_power_tables
      Prime.each(47) do |p|
        (1...p).each do |g|
          table = power_table(g, p)
          (1...p).each do |h|
            result = Prime.discrete_log(g, h, p)
            if (x = table[h])
              assert_equal [x, table.size], result, "g=#{g}, h=#{h}, p=#{p}"
              assert_equal h, g.pow(result[0], p)
            else
              assert_nil result, "g=#{g}, h=#{h}, p=#{p}"
            end
          end
        end
      end
    end

    def test_budget_exceeded_raises
      # 227 == 2*113 + 1 is a safe prime and 2 is a primitive root;
      # the subproblem of order 113 needs a table of 11 entries and
      # about 22 group operations.
      h = 2.pow(100, 227)
      assert_raise(Prime::DiscreteLogBudgetExceeded) do
        Prime.discrete_log(2, h, 227, max_table_size: 10)
      end
      assert_raise(Prime::DiscreteLogBudgetExceeded) do
        Prime.discrete_log(2, h, 227, max_steps: 21)
      end
      assert_equal [100, 226], Prime.discrete_log(2, h, 227, max_table_size: 11, max_steps: 22)
    end

    def test_no_solution_is_distinct_from_budget_exceeded
      # 2 is not a power of 4 modulo 227; membership is decided before
      # any budgeted subproblem runs, so even a minimal budget reports
      # no solution instead of raising.
      assert_nil Prime.discrete_log(4, 2, 227, max_table_size: 1, max_steps: 1)
    end

    def test_argument_validation
      assert_raise(ArgumentError) { Prime.discrete_log(0, 1, 7) }
      assert_raise(ArgumentError) { Prime.discrete_log(14, 1, 7) } # 14 % 7 == 0
      assert_raise(ArgumentError) { Prime.discrete_log(1, 0, 7) }
      assert_raise(ArgumentError) { Prime.discrete_log(1, 21, 7) } # 21 % 7 == 0
      assert_raise(ArgumentError) { Prime.discrete_log(2, 1, 1) }
      assert_raise(ArgumentError) { Prime.discrete_log(2, 1, 15) }
      assert_raise(ArgumentError) { Prime.discrete_log(2, 1, 7, max_table_size: 0) }
      assert_raise(ArgumentError) { Prime.discrete_log(2, 1, 7, max_steps: 0) }
    end
  end

  class TestInteger < Test::Unit::TestCase
    def test_prime_division
      pd = PRIMES.inject(&:*).prime_division
      assert_equal PRIMES.map{|p| [p, 1]}, pd

      pd = (-PRIMES.inject(&:*)).prime_division
      assert_equal [-1, *PRIMES].map{|p| [p, 1]}, pd
    end

    def test_from_prime_division
      assert_equal PRIMES.inject(&:*), Integer.from_prime_division(PRIMES.map{|p| [p,1]})

      assert_equal(-PRIMES.inject(&:*), Integer.from_prime_division([[-1, 1]] + PRIMES.map{|p| [p,1]}))
    end

    def test_prime?
      PRIMES.each do |p|
        assert_predicate(p, :prime?)
      end

      composites = (0..PRIMES.last).to_a - PRIMES
      composites.each do |c|
        assert_not_predicate(c, :prime?)
      end

      # mersenne numbers
      assert_predicate((2**31-1), :prime?)
      assert_not_predicate((2**32-1), :prime?)

      # fermat numbers
      assert_predicate((2**(2**4)+1), :prime?)
      assert_not_predicate((2**(2**5)+1), :prime?) # Euler!

      # large composite
      assert_not_predicate(((2**13-1) * (2**17-1)), :prime?)

      # factorial
      assert_not_predicate((2...100).inject(&:*), :prime?)

      # negative
      assert_not_predicate(-1, :prime?)
      assert_not_predicate(-2, :prime?)
      assert_not_predicate(-3, :prime?)
      assert_not_predicate(-4, :prime?)

      assert_equal 1229, (1..10_000).count(&:prime?)
      assert_equal 861, (100_000..110_000).count(&:prime?)
    end

    def test_prime_in_ractor
      assert_ractor(<<~RUBY, require: 'prime')
        class Ractor
          alias value take
        end unless Ractor.method_defined? :value # compat with Ruby 3.4 and olders

        # Test usage of private constant...
        assert_equal false, Ractor.new { ((2**13-1) * (2**17-1)).prime? }.value
      RUBY
    end if defined?(Ractor)
  end

  def test_eratosthenes_works_fine_after_timeout
    sieve = Prime::EratosthenesSieve.instance
    sieve.send(:initialize)
    # simulates that Timeout.timeout interrupts Prime::EratosthenesSieve#compute_primes
    class << Integer
      alias_method :org_sqrt, :sqrt
    end
    begin
      def Integer.sqrt(n)
        sleep 10 if /compute_primes/ =~ caller.first
        org_sqrt(n)
      end
      assert_raise(Timeout::Error) do
        Timeout.timeout(0.5) { Prime.each(7*37){} }
      end
    ensure
      class << Integer
        remove_method :sqrt
        alias_method :sqrt, :org_sqrt
        remove_method :org_sqrt
      end
    end

    assert_not_include Prime.each(7*37).to_a, 7*37, "[ruby-dev:39465]"
  end
end
