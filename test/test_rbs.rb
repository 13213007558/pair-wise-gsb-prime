return unless RUBY_VERSION >= "3.0.0"

require "test/unit"

require "rbs"
require "rbs/unit_test"

require "prime"

module RBSTypeTest
  class PrimeSingletonTest < Test::Unit::TestCase
    include RBS::UnitTest::TypeAssertions

    library "singleton", "prime"
    testing "singleton(::Prime)"

    def test_each
      assert_send_type(
        "() { (::Integer) -> void } -> void",
        Prime, :each, &proc { break_from_block }
      )

      assert_send_type(
        "(::Integer? ubound) { (::Integer) -> void } -> void",
        Prime, :each, 10, &proc { break_from_block }
      )

      assert_send_type(
        "(::Integer? ubound, ::Prime::PseudoPrimeGenerator generator) { (::Integer) -> void } -> void",
        Prime, :each, 10, Prime::TrialDivisionGenerator.new, &proc { break_from_block }
      )

      assert_send_type(
        "() -> ::Prime::PseudoPrimeGenerator",
        Prime, :each
      )
    end

    def test_int_from_prime_division
      assert_send_type "(::Array[[ ::Integer, ::Integer ]]) -> ::Integer",
                       Prime, :int_from_prime_division, [[3, 1], [19, 1]]
      assert_send_type "(::Array[[ ::Integer, ::Integer ]]) -> ::Rational",
                       Prime, :int_from_prime_division, [[-4, -2]]
    end

    def test_prime?
      assert_send_type "(::Integer) -> bool",
                       Prime, :prime?, 57
    end

    def test_prime_division
      assert_send_type "(::Integer) -> ::Array[[ ::Integer, ::Integer ]]",
                       Prime, :prime_division, 57
    end

    def test_instance
      assert_send_type "() -> ::Prime",
                       Prime, :instance
    end
  end

  class PrimeBernoulliSingletonTest < Test::Unit::TestCase
    include RBS::UnitTest::TypeAssertions

    library "singleton", "prime"
    testing "singleton(::Prime)"

    def test_bernoulli
      assert_send_type "(::Integer) -> ::Rational",
                       Prime, :bernoulli, 12
    end

    def test_faulhaber
      assert_send_type "(::Integer, ::Integer) -> ::Rational",
                       Prime, :faulhaber, 2, 10
      assert_send_type "(::Integer, ::Range[::Integer]) -> ::Rational",
                       Prime, :faulhaber, 2, 1..10
      assert_send_type "(::Integer, ::Range[::Integer]) -> ::Rational",
                       Prime, :faulhaber, 2, -3...10
    end
  end

  class PrimeBernoulliInstanceTest < Test::Unit::TestCase
    include RBS::UnitTest::TypeAssertions

    library "singleton", "prime"
    testing "::Prime"

    def test_bernoulli
      assert_send_type "(::Integer) -> ::Rational",
                       Prime.instance, :bernoulli, 12
    end

    def test_faulhaber
      assert_send_type "(::Integer, ::Integer) -> ::Rational",
                       Prime.instance, :faulhaber, 2, 10
      assert_send_type "(::Integer, ::Range[::Integer]) -> ::Rational",
                       Prime.instance, :faulhaber, 2, 1..10
    end
  end

  class BernoulliTest < Test::Unit::TestCase
    include RBS::UnitTest::TypeAssertions

    library "singleton", "prime"
    testing "::Prime::Bernoulli"

    def test_aref
      assert_send_type "(::Integer) -> ::Rational",
                       Prime::Bernoulli.instance, :[], 6
    end

    def test_upto
      assert_send_type "(::Integer) -> ::Array[::Rational]",
                       Prime::Bernoulli.instance, :upto, 6
    end

    def test_von_staudt_clausen_denominator
      assert_send_type "(::Integer) -> ::Integer",
                       Prime::Bernoulli.instance, :von_staudt_clausen_denominator, 12
    end
  end

  class PrimeInstanceTest < Test::Unit::TestCase
    include RBS::UnitTest::TypeAssertions

    library "singleton", "prime"
    testing "::Prime"

    def test_each
      assert_send_type(
        "() { (::Integer) -> void } -> void",
        Prime.instance, :each, &proc { break_from_block }
      )
      assert_send_type(
        "(::Integer? ubound) { (::Integer) -> void } -> void",
        Prime.instance, :each, 10, &proc { break_from_block }
      )
      assert_send_type(
        "(::Integer? ubound, ::Prime::PseudoPrimeGenerator generator) { (::Integer) -> void } -> void",
        Prime.instance, :each, 10, Prime::TrialDivisionGenerator.new, &proc { break_from_block }
      )
      assert_send_type(
        "() -> ::Prime::PseudoPrimeGenerator",
        Prime.instance, :each
      )
    end

    def test_int_from_prime_division
      assert_send_type "(::Array[[ ::Integer, ::Integer ]]) -> ::Integer",
                       Prime.instance, :int_from_prime_division, [[3, 1], [19, 1]]
      assert_send_type "(::Array[[ ::Integer, ::Integer ]]) -> ::Rational",
                       Prime.instance, :int_from_prime_division, [[-4, -2]]
    end

    def test_prime?
      assert_send_type "(::Integer value) -> bool",
                       Prime.instance, :prime?, 57
    end

    def test_prime_division
      assert_send_type "(::Integer) -> ::Array[[ ::Integer, ::Integer ]]",
                       Prime.instance, :prime_division, 57
    end
  end
end
