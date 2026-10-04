# frozen_string_literal: false
require 'test/unit'
require 'prime'

class TestBinaryQuadraticForm < Test::Unit::TestCase
  def form(coefficients)
    Prime::BinaryQuadraticForm.new(*coefficients)
  end

  def test_enumerates_primitive_reduced_forms
    assert_equal [[1, 1, 6], [2, -1, 3], [2, 1, 3]],
                 Prime::BinaryQuadraticForm.forms(-23).map(&:to_a)
    assert_equal [[1, 1, 4], [2, 1, 2]],
                 Prime::BinaryQuadraticForm.forms(-15).map(&:to_a)
    assert_equal [[1, 0, 5], [2, 2, 3]],
                 Prime::BinaryQuadraticForm.forms(-20).map(&:to_a)
    assert_equal [[1, 0, 1]], Prime::BinaryQuadraticForm.forms(-4).map(&:to_a)
    assert_equal [[1, 1, 1]], Prime::BinaryQuadraticForm.forms(-3).map(&:to_a)
  end

  def test_enumeration_returns_enumerator_without_block
    enumerator = Prime::BinaryQuadraticForm.each(-23)
    assert_kind_of Enumerator, enumerator
    assert_equal [[1, 1, 6], [2, -1, 3], [2, 1, 3]],
                 enumerator.map(&:to_a)
  end

  def test_multiplication_table_for_discriminant_minus_23
    identity, inverse, generator = Prime::BinaryQuadraticForm.forms(-23)
    table = [
      [identity, inverse, generator],
      [inverse, generator, identity],
      [generator, identity, inverse]
    ]

    [identity, inverse, generator].each_with_index do |left, x_index|
      [identity, inverse, generator].each_with_index do |right, y_index|
        assert_equal table[x_index][y_index], left * right
      end
    end

    assert_equal identity, identity * identity
    assert_equal generator, inverse * inverse
    assert_equal inverse, generator * generator
    assert_equal identity, generator * inverse
    assert_equal identity, inverse * generator
  end

  def test_gauss_composition_for_order_two_classes
    identity_d15 = form([1, 1, 4])
    ambiguous_d15 = form([2, 1, 2])
    assert_equal identity_d15, ambiguous_d15 * ambiguous_d15

    identity_d20 = form([1, 0, 5])
    ambiguous_d20 = form([2, 2, 3])
    assert_equal identity_d20, ambiguous_d20 * ambiguous_d20

    identity_d35 = form([1, 1, 9])
    ambiguous_d35 = form([3, 1, 3])
    assert_equal identity_d35, ambiguous_d35 * ambiguous_d35
  end

  def test_associativity_on_known_small_class_groups
    [-15, -20, -23, -31, -39, -84, -107].each do |discriminant|
      forms = Prime::BinaryQuadraticForm.forms(discriminant)
      forms.each do |x|
        forms.each do |y|
          forms.each do |z|
            assert_equal(x * (y * z), (x * y) * z, [discriminant, x, y, z].inspect)
          end
        end
      end
    end
  end

  def test_inverse_uses_unified_boundary_signs
    assert_equal form([1, 1, 1]), form([1, 1, 1]).inverse
    assert_equal form([1, 0, 1]), form([1, 0, 1]).inverse
    assert_equal form([2, 1, 2]), form([2, 1, 2]).inverse
    assert_equal form([2, 2, 3]), form([2, 2, 3]).inverse
    assert_equal form([2, -1, 3]), form([2, 1, 3]).inverse
    assert_equal form([2, 1, 3]), form([2, -1, 3]).inverse
  end

  def test_constructors_normalize_noncanonical_equivalent_forms
    assert_equal form([2, -1, 3]), Prime::BinaryQuadraticForm.new(2, 3, 4)
    assert_equal form([2, -1, 3]), Prime::BinaryQuadraticForm.canonical(3, 1, 2)
    assert_equal form([1, 0, 1]), Prime::BinaryQuadraticForm.new(-1, 0, -1)
  end

  def test_identity_and_inverse_group_laws
    [-3, -4, -15, -20, -23, -31, -39, -84, -107].each do |discriminant|
      identity = Prime::BinaryQuadraticForm.identity(discriminant)
      Prime::BinaryQuadraticForm.forms(discriminant).each do |member|
        assert_equal identity, member * member.inverse
        assert_equal identity, member.inverse * member
        assert_equal member, member * identity
        assert_equal member, identity * member
      end
    end
  end

  def test_known_class_numbers
    { -3 => 1, -4 => 1, -15 => 2, -20 => 2, -23 => 3, -31 => 3, -39 => 4, -107 => 3 }.each do |discriminant, count|
      assert_equal count, Prime::BinaryQuadraticForm.forms(discriminant).size
    end
  end

  def test_invalid_discriminants_explain_the_reason
    { -1 => 'not congruent', -2 => 'not congruent', 0 => 'negative', 1 => 'negative',
      -12 => 'D/4=-3 is not congruent', -16 => 'not fundamental',
      -36 => 'not squarefree', -63 => 'not squarefree',
      -75 => 'not fundamental' }.each do |discriminant, message|
      error = Prime::BinaryQuadraticForm.fundamental_discriminant_error(discriminant)
      assert_include error, message
      raised = assert_raise(ArgumentError) { Prime::BinaryQuadraticForm.forms(discriminant) }
      assert_include raised.message, message
    end
  end

  def test_non_integer_discriminant
    assert_include Prime::BinaryQuadraticForm.fundamental_discriminant_error(-4.0),
                   'discriminant must be an integer'
  end

  def test_composition_requires_matching_discriminants
    d15 = form([2, 1, 2])
    d20 = form([2, 2, 3])
    error = assert_raise(ArgumentError) { d15 * d20 }
    assert_include error.message, 'both forms must have discriminant -15'
  end
end
