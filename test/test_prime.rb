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

  class TestPocklington < Test::Unit::TestCase
    def test_certificates_for_known_primes
      [2, 3, 5, 7, 11, 13, 23, 47, 65537].each do |n|
        certificate = Prime.pocklington_certificate(n)
        assert_kind_of Hash, certificate
        assert_equal n, certificate[:prime]
        assert Prime.valid_pocklington_certificate?(certificate)
      end
    end

    def test_large_prime_with_partial_known_factors
      n = 2**61 - 1
      known_factors = [
        [2, 1], [3, 2], [5, 2], [7, 1], [11, 1], [13, 1],
        [31, 1], [41, 1], [61, 1], [151, 1], [331, 1], [1321, 1]
      ]

      certificate = Prime.pocklington_certificate(n, known_factors)
      assert_kind_of Hash, certificate
      assert Prime.valid_pocklington_certificate?(Marshal.load(Marshal.dump(certificate)))
    end

    def test_verification_does_not_use_primality_or_generator_cache
      certificate = Prime.pocklington_certificate(47, [[23, 1]])
      guarded = Marshal.load(Marshal.dump(certificate))
      calls = []
      trace = TracePoint.new(:call, :c_call) do |event|
        calls << event.method_id if event.method_id == :prime?
      end
      begin
        trace.enable { assert Prime.valid_pocklington_certificate?(guarded) }
      ensure
        trace.disable
      end
      assert_empty calls
    end

    def test_tampering_with_each_certificate_field
      certificate = Prime.pocklington_certificate(23, [[11, 1]])

      integer_paths(certificate).each do |path|
        invalid = Marshal.load(Marshal.dump(certificate))
        target = path[0..-2].inject(invalid) { |object, key| object[key] }
        target[path.last] = path.last == :witness ? 1 : target[path.last] + 2
        assert_equal false, Prime.valid_pocklington_certificate?(invalid), path.inspect
      end
    end

    def test_tampered_factorization
      certificate = Prime.pocklington_certificate(23, [[11, 1]])

      invalid = Marshal.load(Marshal.dump(certificate))
      invalid[:factors] << [2, 1, {prime: 2}]
      assert_equal false, Prime.valid_pocklington_certificate?(invalid)

      invalid = Marshal.load(Marshal.dump(certificate))
      invalid[:factors][0][2] = {prime: 2}
      assert_equal false, Prime.valid_pocklington_certificate?(invalid)

      duplicate = Marshal.load(Marshal.dump(certificate))
      duplicate[:factors] << Marshal.load(Marshal.dump(duplicate[:factors][0]))
      assert_equal false, Prime.valid_pocklington_certificate?(duplicate)

      five = {prime: 5, factors: [[2, 2, {prime: 2}]], witness: 2}
      invalid_five = Marshal.load(Marshal.dump(five))
      invalid_five[:factors][0][1] = 1
      assert_equal false, Prime.valid_pocklington_certificate?(invalid_five)
    end

    def test_circular_certificates_are_rejected
      certificate = Prime.pocklington_certificate(23, [[11, 1]])

      self_cycle = Marshal.load(Marshal.dump(certificate))
      self_cycle[:factors][0][2] = self_cycle
      assert_equal false, Prime.valid_pocklington_certificate?(self_cycle)

      pair = {prime: 23, factors: [[11, 1, nil]], witness: 2}
      pair_child = {prime: 11, factors: [[23, 1, pair], [5, 1, {prime: 5, factors: [[2, 2, {prime: 2}]], witness: 2}]], witness: 2}
      pair[:factors][0][2] = pair_child
      assert_equal false, Prime.valid_pocklington_certificate?(pair)
    end

    def test_witness_must_be_in_range
      certificate = Prime.pocklington_certificate(23, [[11, 1]])

      [0, 1, 22, 23, -2].each do |witness|
        invalid = Marshal.load(Marshal.dump(certificate))
        invalid[:witness] = witness
        assert_equal false, Prime.valid_pocklington_certificate?(invalid)
      end
    end

    def test_insufficient_known_coverage_is_unproved
      n = 2**61 - 1
      assert_equal Prime::Pocklington::UNPROVED, Prime.pocklington_certificate(n, [[2, 1]])
      assert_equal Prime::Pocklington::UNPROVED, Prime.pocklington_certificate(13, [[3, 1]])
      assert_equal Prime::Pocklington::UNPROVED, Prime.pocklington_certificate(23, [[2, 1]])
    end

    def test_composite_is_unproved_not_false_or_composite
      [4, 9, 15, 25, 561].each do |n|
        assert_equal Prime::Pocklington::UNPROVED, Prime.pocklington_certificate(n)
      end

      assert_equal Prime::Pocklington::UNPROVED, Prime.pocklington_certificate(9, [[2, 2]])
      assert_equal Prime::Pocklington::UNPROVED, Prime.pocklington_certificate(25, [[2, 3]])
    end

    def test_non_certifiable_small_factors_are_unproved
      assert_equal Prime::Pocklington::UNPROVED, Prime.pocklington_certificate(17, [[2, 2]])
    end

    def test_malformed_certificates_are_false
      malformed = [
        nil, 1, "23", [], {}, {prime: 4},
        {prime: 2, factors: [], witness: 2},
        {prime: 2, extra: 1},
        {prime: 5, factors: [], witness: 2},
        {prime: 5, factors: [[4, 1, {prime: 4}]], witness: 2},
        {prime: 5, factors: [[2, 0, {prime: 2}]], witness: 2},
        {prime: 5, factors: [[2, 1, {prime: 3}]], witness: 2},
        {prime: 5, factors: [[2, 1, {prime: 2}]], witness: 2.0}
      ]

      malformed.each do |certificate|
        assert_equal false, Prime.valid_pocklington_certificate?(certificate)
      end
    end

    def test_invalid_known_factor_arguments
      assert_raise(ArgumentError) { Prime.pocklington_certificate(23, [[11]]) }
      assert_raise(ArgumentError) { Prime.pocklington_certificate(23, [[11, 0]]) }
      assert_raise(ArgumentError) { Prime.pocklington_certificate(23, [[11, 1, :bad]]) }
      assert_raise(ArgumentError) { Prime.pocklington_certificate(23, [[11, 1], [11, 1]]) }
      assert_raise(ArgumentError) { Prime.pocklington_certificate("23", [[11, 1]]) }
      assert_raise(ArgumentError) { Prime.pocklington_certificate(23, nil, Object.new) }
    end

    private

    def integer_paths(value, path = [])
      case value
      when Hash
        value.flat_map do |key, child|
          integer_paths(child, path + [key])
        end
      when Array
        value.each_with_index.flat_map do |child, index|
          integer_paths(child, path + [index])
        end
      when Integer
        [path]
      else
        []
      end
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
