# frozen_string_literal: false
require 'test/unit'
require 'prime'

class TestBernoulli < Test::Unit::TestCase
  # B_0 .. B_16 with the B_1 = -1/2 convention.
  KNOWN = [
    Rational(1, 1),     # B_0
    Rational(-1, 2),    # B_1
    Rational(1, 6),     # B_2
    Rational(0, 1),     # B_3
    Rational(-1, 30),   # B_4
    Rational(0, 1),     # B_5
    Rational(1, 42),    # B_6
    Rational(0, 1),     # B_7
    Rational(-1, 30),   # B_8
    Rational(0, 1),     # B_9
    Rational(5, 66),    # B_10
    Rational(0, 1),     # B_11
    Rational(-691, 2730), # B_12
    Rational(0, 1),     # B_13
    Rational(7, 6),     # B_14
    Rational(0, 1),     # B_15
    Rational(-3617, 510), # B_16
  ]

  def test_known_values
    KNOWN.each_with_index do |expected, n|
      assert_equal expected, Prime.bernoulli(n), "B_#{n}"
    end
  end

  def test_b1_sign_convention
    # The generating function x/(exp(x)-1) fixes B_1 = -1/2.
    assert_equal Rational(-1, 2), Prime.bernoulli(1)
    assert_operator Prime.bernoulli(1), :<, 0
  end

  def test_results_are_exact_rationals
    0.upto(30) do |n|
      assert_instance_of Rational, Prime.bernoulli(n), "B_#{n}"
    end
  end

  def test_odd_orders_vanish
    3.step(31, 2) do |n|
      assert_equal 0, Prime.bernoulli(n), "B_#{n}"
    end
  end

  def test_rejects_non_integer_order
    assert_raise(ArgumentError) { Prime.bernoulli(-1) }
    assert_raise(ArgumentError) { Prime.bernoulli(2.0) }
    assert_raise(ArgumentError) { Prime.bernoulli(Rational(2, 1)) }
    assert_raise(ArgumentError) { Prime.bernoulli("4") }
  end

  def test_upto_generates_a_run_and_reuses_intermediate_results
    generator = Prime::Bernoulli.instance
    first_run = generator.upto(10)
    assert_equal KNOWN[0..10], first_run

    extended = generator.upto(16)
    assert_equal KNOWN, extended

    # Values computed in the first run must be reused, not recomputed.
    0.upto(10) do |n|
      assert_same first_run[n], extended[n], "B_#{n} should come from the cache"
      assert_same first_run[n], generator[n], "B_#{n} should come from the cache"
    end
  end

  def test_von_staudt_clausen_denominators
    generator = Prime::Bernoulli.instance
    {
      2 => 6, 4 => 30, 6 => 42, 8 => 30, 10 => 66,
      12 => 2730, 14 => 6, 16 => 510, 18 => 798, 20 => 330,
    }.each do |n, denominator|
      assert_equal denominator, generator.von_staudt_clausen_denominator(n),
                   "von Staudt-Clausen denominator of B_#{n}"
      assert_equal denominator, generator[n].denominator, "denominator of B_#{n}"
    end
  end

  def test_even_order_denominators_against_independent_prime_product
    2.step(60, 2) do |n|
      expected = 1
      Prime.each(n + 1) do |prime|
        expected *= prime if n % (prime - 1) == 0
      end
      assert_equal expected, Prime.bernoulli(n).denominator, "denominator of B_#{n}"
    end
  end

  def test_von_staudt_clausen_denominator_argument_checking
    generator = Prime::Bernoulli.instance
    assert_raise(ArgumentError) { generator.von_staudt_clausen_denominator(3) }
    assert_raise(ArgumentError) { generator.von_staudt_clausen_denominator(0) }
    assert_raise(ArgumentError) { generator.von_staudt_clausen_denominator(2.0) }
  end
end

class TestFaulhaber < Test::Unit::TestCase
  def brute_force(power, first, last)
    return 0 if last < first
    return last - first + 1 if power.zero?
    first.upto(last).sum { |k| k**power }
  end

  def test_integer_bound_includes_the_upper_end
    assert_equal Rational(55, 1), Prime.faulhaber(1, 10)   # 1 + 2 + ... + 10
    assert_equal Rational(385, 1), Prime.faulhaber(2, 10)  # 1**2 + ... + 10**2
    assert_equal Rational(1, 1), Prime.faulhaber(2, 1)     # just 1**2
  end

  def test_closed_forms
    1.upto(50) do |n|
      assert_equal n * (n + 1) / 2, Prime.faulhaber(1, n)
      assert_equal n * (n + 1) * (2 * n + 1) / 6, Prime.faulhaber(2, n)
      assert_equal (n * (n + 1) / 2)**2, Prime.faulhaber(3, n)
    end
  end

  def test_integer_bound_below_one_is_empty
    assert_equal 0, Prime.faulhaber(1, 0)
    assert_equal 0, Prime.faulhaber(2, 0)
    assert_equal 0, Prime.faulhaber(2, -5)
  end

  def test_range_form_matches_integer_form
    0.upto(5) do |power|
      assert_equal Prime.faulhaber(power, 20), Prime.faulhaber(power, 1..20)
    end
  end

  def test_exclusive_range_excludes_the_end
    assert_equal 1 + 2 + 3 + 4, Prime.faulhaber(1, 1...5)
    assert_equal 1 + 4 + 9 + 16, Prime.faulhaber(2, 1...5)
    assert_equal Prime.faulhaber(3, 1..9), Prime.faulhaber(3, 1...10)
  end

  def test_negative_endpoints
    assert_equal(-3 + -2 + -1, Prime.faulhaber(1, -3..-1))
    assert_equal 9 + 4 + 1, Prime.faulhaber(2, -3..-1)
    assert_equal(-2 + -1 + 0 + 1 + 2, Prime.faulhaber(1, -2..2))
    assert_equal 2 * (1 + 4), Prime.faulhaber(2, -2..2)
    # Odd powers cancel over symmetric ranges.
    assert_equal 0, Prime.faulhaber(3, -5..5)
    assert_equal 0, Prime.faulhaber(1, -10..10)
    # Ranges crossing zero agree with the difference of the two sides.
    assert_equal Prime.faulhaber(2, -4..-1) + Prime.faulhaber(2, 4),
                 Prime.faulhaber(2, -4..4)
  end

  def test_empty_ranges
    assert_equal 0, Prime.faulhaber(2, 5..2)
    assert_equal 0, Prime.faulhaber(2, 3...3)
    assert_equal 0, Prime.faulhaber(2, 0..-1)
    assert_equal 0, Prime.faulhaber(2, -1..-3)
    assert_equal 0, Prime.faulhaber(0, 5..2)
    assert_instance_of Rational, Prime.faulhaber(2, 5..2)
  end

  def test_zero_power_counts_the_terms
    assert_equal 10, Prime.faulhaber(0, 10)
    assert_equal 3, Prime.faulhaber(0, 2..4)
    assert_equal 5, Prime.faulhaber(0, -2..2)
  end

  def test_against_brute_force
    0.upto(6) do |power|
      [-10, -3, 0, 1, 5].each do |first|
        [first - 1, first, first + 4, first + 9].each do |last|
          assert_equal brute_force(power, first, last),
                       Prime.faulhaber(power, first..last),
                       "power=#{power}, range=#{first}..#{last}"
        end
      end
    end
  end

  def test_results_are_exact_rationals
    assert_instance_of Rational, Prime.faulhaber(2, 10)
    assert_instance_of Rational, Prime.faulhaber(2, 1..10)
    assert_instance_of Rational, Prime.faulhaber(2, -3..-1)
    # Sums of integer powers are integers, so the denominator must be 1.
    assert_equal 1, Prime.faulhaber(7, 100).denominator
    assert_equal 1, Prime.faulhaber(4, -20..20).denominator
  end

  def test_exact_for_large_arguments
    n = 10**6
    assert_equal Rational(n * (n + 1) / 2, 1), Prime.faulhaber(1, n)
    assert_equal n * (n + 1) * (2 * n + 1) / 6, Prime.faulhaber(2, n)
    assert_equal (n * (n + 1) / 2)**2, Prime.faulhaber(3, n)
  end

  def test_rejects_non_exact_types
    # Floats and other non-integer types must not be silently converted
    # to Rational and passed off as exact values.
    assert_raise(ArgumentError) { Prime.faulhaber(2.0, 10) }
    assert_raise(ArgumentError) { Prime.faulhaber(-1, 10) }
    assert_raise(ArgumentError) { Prime.faulhaber(2, 10.0) }
    assert_raise(ArgumentError) { Prime.faulhaber(2, 1.0..10) }
    assert_raise(ArgumentError) { Prime.faulhaber(2, 1..10.0) }
    assert_raise(ArgumentError) { Prime.faulhaber(2, "10") }
    assert_raise(ArgumentError) { Prime.faulhaber(2, nil) }
  end
end
