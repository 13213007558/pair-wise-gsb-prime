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

  class BinaryQuadraticFormSingletonTest < Test::Unit::TestCase
    include RBS::UnitTest::TypeAssertions

    library "singleton", "prime"
    testing "singleton(::Prime::BinaryQuadraticForm)"

    def test_class_api
      assert_send_type "(untyped) -> bool",
                       Prime::BinaryQuadraticForm, :fundamental_discriminant?, -23
      assert_send_type "(untyped) -> ::String?",
                       Prime::BinaryQuadraticForm, :fundamental_discriminant_error, -23
      assert_send_type "(::Integer) -> ::Array[::Prime::BinaryQuadraticForm]",
                       Prime::BinaryQuadraticForm, :forms, -23
      assert_send_type "(::Integer) -> ::Prime::BinaryQuadraticForm",
                       Prime::BinaryQuadraticForm, :identity, -23
    end
  end

  class BinaryQuadraticFormTest < Test::Unit::TestCase
    include RBS::UnitTest::TypeAssertions

    library "singleton", "prime"
    testing "::Prime::BinaryQuadraticForm"

    def test_instance_api
      form = Prime::BinaryQuadraticForm.new(2, 1, 3)
      inverse = Prime::BinaryQuadraticForm.new(2, -1, 3)

      assert_send_type "(::Prime::BinaryQuadraticForm) -> ::Prime::BinaryQuadraticForm",
                       form, :compose, inverse
      assert_send_type "() -> ::Prime::BinaryQuadraticForm", form, :inverse
      assert_send_type "() -> bool", form, :identity?
      assert_send_type "() -> [ ::Integer, ::Integer, ::Integer ]", form, :to_a
      assert_send_type "() -> ::String", form, :inspect
    end
  end
end
