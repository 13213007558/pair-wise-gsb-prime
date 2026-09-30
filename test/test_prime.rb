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

  def brute_force_square_roots(a, m)
    (0...m).select { |x| x ** 2 % m == a % m }
  end

  def assert_square_roots(a, m)
    expected = brute_force_square_roots(a, m)
    roots = Prime.square_roots(a, m)
    actual = roots.to_a
    assert_equal expected.sort, actual.sort
    assert_equal actual, actual.uniq
    assert actual.all? { |x| x.between?(0, m - 1) }
    assert_equal expected.length, roots.size
    assert_equal expected.length, Prime.square_root_count(a, m)
  end

  def test_square_roots_small_moduli
    (1..200).each do |m|
      (0...m).each do |a|
        assert_square_roots(a, m)
      end
    end
  end

  def test_square_roots_normalize_a_and_accept_blocks
    assert_equal [1, 3, 5, 7], Prime.square_roots(-7, 8).to_a.sort
    roots = []
    assert_nil Prime.square_roots(1, 8) { |x| roots << x }
    assert_equal [1, 3, 5, 7], roots.sort
  end

  def test_square_roots_modulus_one_and_no_solutions
    assert_equal [0], Prime.square_roots(0, 1).to_a
    assert_equal [0], Prime.square_roots(7, 1).to_a
    assert_equal 1, Prime.square_root_count(7, 1)
    assert_equal [], Prime.square_roots(2, 4).to_a
    assert_equal 0, Prime.square_root_count(2, 4)
    assert_equal 0, Prime.square_roots(2, 4).size
  end

  def test_square_roots_non_coprime_prime_powers
    assert_square_roots(12, 72)
    assert_square_roots(18, 72)
    assert_square_roots(0, 144)
    assert_square_roots(36, 144)
  end

  def test_square_roots_large_odd_prime_powers
    p = 101
    e = 5
    m = p ** e

    roots = Prime.square_roots(4, m).to_a.sort
    assert_equal [2, m - 2], roots
    assert_equal 2, Prime.square_root_count(4, m)

    a = p ** 2 * 4
    roots = Prime.square_roots(a, m)
    all_roots = roots.to_a
    assert_equal 2 * p, all_roots.length
    assert_equal all_roots, all_roots.uniq
    assert(all_roots.all? { |x| x ** 2 % m == a })

    roots = Prime.square_roots(0, m)
    zero_roots = roots.to_a
    assert_equal p ** 2, zero_roots.length
    assert_equal zero_roots, zero_roots.uniq
    assert(zero_roots.all? { |x| x ** 2 % m == 0 })

    assert_equal 0, Prime.square_root_count(p * 2, p ** 3)
    assert_equal 0, Prime.square_root_count(2, p ** 3)
  end

  def test_square_roots_instance_and_custom_generator
    enum = Prime.instance.square_roots(1, 15, Prime::TrialDivisionGenerator.new)
    assert_equal 4, enum.size
    assert_equal [1, 4, 11, 14], enum.to_a.sort
    assert_equal 4, Prime.instance.square_root_count(1, 15,
                                                       Prime::TrialDivisionGenerator.new)
  end

  def test_square_roots_large_power_of_two
    e = 100
    m = 2 ** e
    assert_equal [1, m / 2 - 1, m / 2 + 1, m - 1],
                 Prime.square_roots(1, m).to_a.sort
    assert_equal 4, Prime.square_root_count(1, m)

    a = 4
    roots = Prime.square_roots(a, m)
    expected_roots = [
      2,
      2 ** 98 - 2,
      2 ** 98 + 2,
      2 ** 99 - 2,
      2 ** 99 + 2,
      3 * 2 ** 98 - 2,
      3 * 2 ** 98 + 2,
      m - 2
    ]
    assert_equal expected_roots, roots.to_a.sort
    assert_equal 8, roots.size
    assert_equal 8, Prime.square_root_count(a, m)

    roots = Prime.square_roots(0, m)
    assert_equal 2 ** 50, roots.size
    first = roots.first(30)
    assert_equal 30, first.length
    assert_equal first, first.uniq
    assert(first.all? { |x| x ** 2 % m == 0 })

    roots = Prime.square_roots(2 ** 98, m)
    assert_equal 2 ** 50, roots.size
    first = roots.first(30)
    assert_equal 30, first.length
    assert_equal first, first.uniq
    assert(first.all? { |x| x ** 2 % m == 2 ** 98 })

    assert_equal 0, Prime.square_root_count(3, 2 ** 20)
  end

  def test_square_roots_are_lazy_and_unique
    m = PRIMES[1, 40].inject(:*)
    roots = Prime.square_roots(1, m)
    assert_equal 2 ** 40, roots.size
    first = roots.first(5)
    assert_equal 5, first.length
    assert_equal first, first.uniq
    assert(first.all? { |x| x ** 2 % m == 1 })
  end

  def test_square_roots_arguments
    assert_raise(ArgumentError) { Prime.square_roots(1, 0) }
    assert_raise(ArgumentError) { Prime.square_roots(1, -2) }
    assert_raise(ArgumentError) { Prime.square_roots(1.0, 2) }
    assert_raise(ArgumentError) { Prime.square_roots(1, 2, Object.new) }
  end
end
