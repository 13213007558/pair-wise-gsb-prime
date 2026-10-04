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

  def test_bernoulli_numbers_are_exact_rationals
    expected = {
      0 => Rational(1),
      1 => Rational(-1, 2),
      2 => Rational(1, 6),
      3 => Rational(0),
      4 => Rational(-1, 30),
      5 => Rational(0),
      6 => Rational(1, 42),
      8 => Rational(-1, 30),
      10 => Rational(5, 66),
      12 => Rational(-691, 2730),
      14 => Rational(7, 6)
    }

    expected.each do |order, value|
      result = Prime.bernoulli_number(order)
      assert_equal value, result
      assert_instance_of Rational, result
    end

    numbers = Prime.bernoulli_numbers(6)
    assert_equal expected.values_at(0, 1, 2, 3, 4, 5, 6), numbers
    assert(numbers.all? { |number| number.is_a?(Rational) })
  end

  def test_bernoulli_calculator_reuses_generated_values
    calculator = Prime.bernoulli_numbers
    assert_kind_of Prime::Bernoulli, calculator

    assert_equal Rational(-691, 2730), calculator[12]
    assert_equal [
      Rational(1), Rational(-1, 2), Rational(1, 6), Rational(0),
      Rational(-1, 30), Rational(0), Rational(1, 42), Rational(0),
      Rational(-1, 30), Rational(0)
    ], calculator.upto(9)
    assert_same calculator, Prime.bernoulli_numbers
  end

  def test_even_bernoulli_numbers_satisfy_von_staudt_clausen
    calculator = Prime::Bernoulli.new

    (2..20).step(2) do |order|
      terms = calculator.von_staudt_clausen_terms(order)
      denominator = terms.inject(1) { |product, term| product * term.denominator }

      assert_equal denominator, Prime.bernoulli_number(order).denominator
      assert_equal 1, (Prime.bernoulli_number(order) + terms.sum).denominator
      assert calculator.von_staudt_clausen_valid?(order)
    end

    assert_equal [Rational(1, 2), Rational(1, 3), Rational(1, 5),
                  Rational(1, 7), Rational(1, 13)],
                 calculator.von_staudt_clausen_terms(12)
  end

  def test_faulhaber_sum_uses_one_through_positive_upper
    assert_equal Rational(0), Prime.faulhaber_sum(0, -3)
    assert_equal Rational(0), Prime.faulhaber_sum(0, 0)
    assert_equal Rational(3), Prime.faulhaber_sum(0, 3)
    assert_equal Rational(0), Prime.faulhaber_sum(1, 0)
    assert_equal Rational(55), Prime.faulhaber_sum(1, 10)
    assert_equal Rational(385), Prime.faulhaber_sum(2, 10)
    assert_equal Rational(3025), Prime.faulhaber_sum(3, 10)

    0.upto(6) do |power|
      0.upto(12) do |upper|
        result = Prime.faulhaber_sum(power, upper)
        expected = (1..upper).sum { |number| number ** power }.to_r
        assert_equal expected, result
        assert_instance_of Rational, result
      end
    end
  end

  def test_power_sum_includes_negative_endpoints_and_represents_empty_ranges
    assert_equal Rational(0), Prime.power_sum(1, -2, 2)
    assert_equal Rational(10), Prime.power_sum(2, -2, 2)
    assert_equal Rational(5), Prime.power_sum(0, -2, 2)
    assert_equal Rational(10), Prime.power_sum(2, -2..2)
    assert_equal Rational(6), Prime.power_sum(2, -2...2)

    assert_equal Rational(0), Prime.power_sum(3, 5, 4)
    assert_equal Rational(0), Prime.power_sum(3, 5...5)
    assert_equal Rational(0), Prime.power_sum(0, 5, 4)

    [-2, 0, 2].each do |lower|
      lower.upto(3) do |upper|
        0.upto(5) do |power|
          expected = lower.upto(upper).sum { |number| number ** power }.to_r
          assert_equal expected, Prime.power_sum(power, lower, upper)
          assert_instance_of Rational, Prime.power_sum(power, lower, upper)
        end
      end
    end
  end

  def test_exact_power_series_interfaces_reject_floats
    assert_raise(ArgumentError) { Prime.bernoulli_number(1.0) }
    assert_raise(ArgumentError) { Prime.faulhaber_sum(2, 3.0) }
    assert_raise(ArgumentError) { Prime.power_sum(2, 1.0, 3) }
    assert_raise(ArgumentError) { Prime.power_sum(2, 1.0..3) }
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
end
