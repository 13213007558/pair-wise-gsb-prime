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

  class TestInt64 < Test::Unit::TestCase
    INT64_MIN = -(2**63)
    INT64_MAX = 2**63 - 1

    # Two distinct primes close to sqrt(2**63), and their product,
    # a semiprime close to the upper bound of the signed 64-bit range.
    SEMIPRIME_P = 3_037_000_493
    SEMIPRIME_Q = 3_037_000_453
    SEMIPRIME = SEMIPRIME_P * SEMIPRIME_Q # 9_223_371_873_002_223_329

    # The largest prime below 2**63.
    LARGE_PRIME = 2**63 - 25

    def test_prime_int64?
      assert_equal false, Prime.prime_int64?(-7)
      assert_equal false, Prime.prime_int64?(0)
      assert_equal false, Prime.prime_int64?(1)
      assert_equal true,  Prime.prime_int64?(2)
      assert_equal true,  Prime.prime_int64?(97)
      assert_equal false, Prime.prime_int64?(99)
      assert_equal true,  Prime.prime_int64?(LARGE_PRIME)
      assert_equal false, Prime.prime_int64?(INT64_MAX)
      assert_equal false, Prime.prime_int64?(INT64_MIN)
      assert_equal true,  Prime.prime_int64?(SEMIPRIME_P)
      assert_equal false, Prime.prime_int64?(SEMIPRIME)

      # Strong pseudoprimes: composites that a probabilistic
      # Miller-Rabin test with only a few bases would accept.
      # 3215031751 is a strong pseudoprime to bases 2, 3, 5, 7.
      assert_equal false, Prime.prime_int64?(3_215_031_751)
      # 3825123056546413051 is a strong pseudoprime to the first
      # nine prime bases.
      assert_equal false, Prime.prime_int64?(3_825_123_056_546_413_051)
    end

    def test_prime_int64?_out_of_range
      assert_raise(RangeError) { Prime.prime_int64?(INT64_MAX + 1) }
      assert_raise(RangeError) { Prime.prime_int64?(INT64_MIN - 1) }
      assert_raise(RangeError) { Prime.prime_int64?(2**64) }
      assert_raise(ArgumentError) { Prime.prime_int64?(1.5) }
      assert_raise(ArgumentError) { Prime.prime_int64?("3") }
    end

    def test_prime_division_int64_matches_prime_division
      (-500..500).each do |n|
        next if n == 0
        result = Prime.prime_division_int64(n, random: Random.new(0))
        assert result.complete?, "expected complete factorization of #{n}"
        assert_equal Prime.prime_division(n), result.to_a
      end
    end

    def test_prime_division_int64_edge_cases
      assert_raise(ZeroDivisionError) { Prime.prime_division_int64(0) }

      one = Prime.prime_division_int64(1)
      assert_equal [], one.to_a
      assert_equal 1, one.remainder
      assert one.complete?

      assert_equal [[-1, 1]], Prime.prime_division_int64(-1).to_a
      assert_equal [[-1, 1], [2, 63]], Prime.prime_division_int64(INT64_MIN).to_a
      assert_equal [[7, 2], [73, 1], [127, 1], [337, 1], [92737, 1], [649657, 1]],
                   Prime.prime_division_int64(INT64_MAX).to_a
    end

    def test_prime_division_int64_out_of_range
      assert_raise(RangeError) { Prime.prime_division_int64(INT64_MAX + 1) }
      assert_raise(RangeError) { Prime.prime_division_int64(INT64_MIN - 1) }
      assert_raise(RangeError) { Prime.prime_division_int64(2**63) }
      assert_raise(ArgumentError) { Prime.prime_division_int64(1.5) }
      assert_raise(ArgumentError) { Prime.prime_division_int64("3") }
      assert_raise(ArgumentError) { Prime.prime_division_int64(6, budget: -1) }
      assert_raise(ArgumentError) { Prime.prime_division_int64(6, budget: 1.5) }
    end

    def test_prime_division_int64_prime_powers
      assert_equal [[2, 62]], Prime.prime_division_int64(2**62).to_a
      assert_equal [[3, 39]], Prime.prime_division_int64(3**39).to_a
      assert_equal [[2_147_483_647, 2]],
                   Prime.prime_division_int64((2**31 - 1)**2).to_a
      # A prime square close to the upper bound.
      assert_equal [[SEMIPRIME_P, 2]],
                   Prime.prime_division_int64(SEMIPRIME_P**2).to_a
    end

    def test_prime_division_int64_semiprime_near_upper_bound
      result = Prime.prime_division_int64(SEMIPRIME, random: Random.new(42))
      assert result.complete?
      assert_equal [[SEMIPRIME_Q, 1], [SEMIPRIME_P, 1]], result.to_a

      negative = Prime.prime_division_int64(-SEMIPRIME, random: Random.new(42))
      assert negative.complete?
      assert_equal [[-1, 1], [SEMIPRIME_Q, 1], [SEMIPRIME_P, 1]], negative.to_a
    end

    def test_prime_division_int64_large_prime
      result = Prime.prime_division_int64(LARGE_PRIME)
      assert result.complete?
      assert_equal [[LARGE_PRIME, 1]], result.to_a
    end

    def test_prime_division_int64_factor_product_and_primality
      values = [
        1, 2, 97, 98, 2**62, 3**39, INT64_MAX, INT64_MIN, LARGE_PRIME,
        SEMIPRIME, -SEMIPRIME, SEMIPRIME_P**2, (2**31 - 1)**2,
        3_215_031_751, 3_825_123_056_546_413_051,
        1_000_003 * 9_223_344_366_799,
      ]
      values.each do |n|
        result = Prime.prime_division_int64(n, random: Random.new(42))
        assert result.complete?, "expected complete factorization of #{n}"
        assert_equal n, result.to_i
        assert_equal n, Integer.from_prime_division(result.to_a)
        result.factors.each_cons(2) do |(p1, _), (p2, _)|
          assert_operator p1, :<, p2, "factors of #{n} are not sorted"
        end
        result.factors.each do |prime, exponent|
          assert_operator exponent, :>=, 1
          next if prime == -1
          assert Prime.prime_int64?(prime), "#{prime} is not a proven prime"
        end
      end
    end

    def test_prime_division_int64_budget_exhausted
      # No Pollard's rho work is possible without a budget, so the
      # semiprime cannot be split; the proven factors (none) and the
      # unfactored remainder are reported separately.
      result = Prime.prime_division_int64(SEMIPRIME, budget: 0)
      assert_false result.complete?
      assert_equal [], result.to_a
      assert_equal SEMIPRIME, result.remainder
      assert_equal SEMIPRIME, result.to_i

      # Factors found before the budget ran out are still proven and
      # reported; only the hard cofactor remains.
      n = 2**10 * 3 * 1_000_003 * 1_000_033
      result = Prime.prime_division_int64(n, budget: 0)
      assert_false result.complete?
      assert_equal [[2, 10], [3, 1]], result.to_a
      assert_equal 1_000_003 * 1_000_033, result.remainder
      assert_equal n, result.to_i

      # Primality and perfect power detection do not consume the
      # budget, so these still complete with budget 0.
      assert Prime.prime_division_int64(LARGE_PRIME, budget: 0).complete?
      power = Prime.prime_division_int64((2**31 - 1)**2, budget: 0)
      assert power.complete?
      assert_equal [[2_147_483_647, 2]], power.to_a
    end

    def test_prime_division_int64_reproducible_with_fixed_seed
      first = Prime.prime_division_int64(SEMIPRIME, random: Random.new(1234))
      second = Prime.prime_division_int64(SEMIPRIME, random: Random.new(1234))
      assert_equal first, second
      assert first.complete?
      assert_equal [[SEMIPRIME_Q, 1], [SEMIPRIME_P, 1]], first.to_a

      # Any seed must lead to the same complete factorization.
      [1, 7, 42, 999].each do |seed|
        result = Prime.prime_division_int64(SEMIPRIME, random: Random.new(seed))
        assert result.complete?
        assert_equal first.to_a, result.to_a
      end
    end

    def test_prime_division_int64_result_object
      result = Prime.prime_division_int64(45, random: Random.new(42))
      assert_equal [[3, 2], [5, 1]], result.to_a
      assert_equal [[3, 2], [5, 1]], result.factors
      assert_equal [3, 5], result.map {|prime, _| prime }
      assert_equal 2, result.each.size
      assert_equal 45, result.to_i
      assert_equal 1, result.remainder
      assert result.complete?
      assert_equal result, Prime.prime_division_int64(45)
      assert_not_equal result, Prime.prime_division_int64(44)
    end

    def test_integer_prime_division_int64
      result = 45.prime_division_int64
      assert result.complete?
      assert_equal [[3, 2], [5, 1]], result.to_a
      assert_raise(ZeroDivisionError) { 0.prime_division_int64 }
      assert_raise(RangeError) { (2**63).prime_division_int64 }
    end
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
