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

  class TestSegmentedMultiplicativeFunctions < Test::Unit::TestCase
    # Per-number baselines computed through Prime.prime_division.
    def phi_by_factorization(n)
      Prime.prime_division(n, Prime::EratosthenesGenerator.new).inject(n) do |phi, (prime, _)|
        phi / prime * (prime - 1)
      end
    end

    def mu_by_factorization(n)
      pd = Prime.prime_division(n, Prime::EratosthenesGenerator.new)
      return 0 if pd.any? {|_, e| e > 1 }
      pd.size.even? ? 1 : -1
    end

    def test_each_totient_matches_prime_division
      Prime.each_totient(1, 1000) do |n, phi|
        assert_equal phi_by_factorization(n), phi, "phi(#{n})"
      end
    end

    def test_each_mobius_matches_prime_division
      Prime.each_mobius(1, 1000) do |n, mu|
        assert_equal mu_by_factorization(n), mu, "mu(#{n})"
      end
    end

    def test_each_totient_divisor_sum_identity
      # sum of phi(d) over the divisors d of n equals n
      n_max = 500
      phis = Prime.each_totient(1, n_max).map {|_, phi| phi }
      sums = Array.new(n_max + 1, 0)
      1.upto(n_max) do |d|
        d.step(n_max, d) {|m| sums[m] += phis[d - 1] }
      end
      assert_equal (1..n_max).to_a, sums[1..-1]
    end

    def test_each_mobius_divisor_sum
      # sum of mu(d) over the divisors d of n equals 1 for n == 1, else 0
      n_max = 500
      mus = Prime.each_mobius(1, n_max).map {|_, mu| mu }
      sums = Array.new(n_max + 1, 0)
      1.upto(n_max) do |d|
        d.step(n_max, d) {|m| sums[m] += mus[d - 1] }
      end
      assert_equal [1] + [0] * (n_max - 1), sums[1..-1]
    end

    def test_segment_size_does_not_change_results
      [[1, 1000], [999_983, 1_001_017]].each do |lo, hi|
        expected_phis = Prime.each_totient(lo, hi).to_a
        expected_mus = Prime.each_mobius(lo, hi).to_a
        [1, 2, 7, 64, hi - lo + 1, 100_000].each do |segment_size|
          assert_equal expected_phis, Prime.each_totient(lo, hi, segment_size: segment_size).to_a,
                       "segment_size=#{segment_size}"
          assert_equal expected_mus, Prime.each_mobius(lo, hi, segment_size: segment_size).to_a,
                       "segment_size=#{segment_size}"
        end
      end
    end

    def test_large_start
      # A table from 1 up to 10**12 could not be allocated; the segmented
      # sieve only keeps the primes up to sqrt(hi) and one segment.
      lo = 10**12 + 39
      hi = lo + 100
      Prime.each_totient(lo, hi) do |n, phi|
        assert_equal phi_by_factorization(n), phi, "phi(#{n})"
      end
      Prime.each_mobius(lo, hi) do |n, mu|
        assert_equal mu_by_factorization(n), mu, "mu(#{n})"
      end
    end

    def test_range_starting_at_one
      assert_equal [[1, 1], [2, 1], [3, 2], [4, 2], [5, 4], [6, 2]],
                   Prime.each_totient(1, 6).to_a
      assert_equal [[1, 1], [2, -1], [3, -1], [4, 0], [5, -1], [6, 1]],
                   Prime.each_mobius(1, 6).to_a
    end

    def test_empty_interval
      assert_equal [], Prime.each_totient(10, 5).to_a
      assert_equal [], Prime.each_mobius(10, 5).to_a
      assert_equal 0, Prime.each_totient(10, 5).size
      Prime.each_totient(10, 5) {|*| flunk "must not yield for an empty interval" }
      Prime.each_mobius(10, 5) {|*| flunk "must not yield for an empty interval" }
    end

    def test_rejects_non_positive_interval
      assert_raise(ArgumentError) { Prime.each_totient(0, 10) }
      assert_raise(ArgumentError) { Prime.each_totient(-5, 5) }
      assert_raise(ArgumentError) { Prime.each_totient(0, 0) }
      assert_raise(ArgumentError) { Prime.each_mobius(0, 10) }
      assert_raise(ArgumentError) { Prime.each_mobius(-5, -1) }
    end

    def test_argument_checking
      assert_raise(ArgumentError) { Prime.each_totient(1.5, 10) }
      assert_raise(ArgumentError) { Prime.each_totient(1, "10") }
      assert_raise(ArgumentError) { Prime.each_mobius(nil, 10) }
      assert_raise(ArgumentError) { Prime.each_totient(1, 10, segment_size: 0) }
      assert_raise(ArgumentError) { Prime.each_totient(1, 10, segment_size: -3) }
      assert_raise(ArgumentError) { Prime.each_mobius(1, 10, segment_size: 1.5) }
    end

    def test_without_block_returns_enumerator
      enum = Prime.each_totient(1, 10)
      assert_kind_of Enumerator, enum
      assert_equal 10, enum.size
      assert_equal 10, enum.to_a.size

      enum = Prime.each_mobius(1, 10)
      assert_kind_of Enumerator, enum
      assert_equal 10, enum.size
      assert_equal 10, enum.to_a.size
    end

    def test_instance_method
      assert_equal Prime.each_totient(1, 10).to_a, Prime.instance.each_totient(1, 10).to_a
      assert_equal Prime.each_mobius(1, 10).to_a, Prime.instance.each_mobius(1, 10).to_a
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
