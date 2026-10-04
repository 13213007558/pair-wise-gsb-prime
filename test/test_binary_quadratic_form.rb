# frozen_string_literal: false
require "test/unit"
require "prime"

class TestBinaryQuadraticForms < Test::Unit::TestCase
  def make(d, a, b, c)
    Prime::QuadraticClassGroup.new(d).send(:form, a, b, c)
  end

  def test_discriminant_validation
    message = assert_raise(ArgumentError) do
      Prime::QuadraticClassGroup.new(-12)
    end.message
    assert_match(/not fundamental/, message)
    assert_match(%r{-12/4 = -3}, message)

    [-1, -5, -9, -13, -16, 0, 3, -100, -36].each do |bad|
      assert_equal(false, Prime::QuadraticClassGroup.fundamental_discriminant?(bad), bad)
      assert_raise(ArgumentError, bad.to_s) { Prime::QuadraticClassGroup.new(bad) }
    end
    [-3, -4, -7, -8, -11, -15, -20, -23, -84, -163].each do |good|
      assert_equal(true, Prime::QuadraticClassGroup.fundamental_discriminant?(good), good)
    end
  end

  def test_non_discriminant_reason_messages
    e1 = assert_raise(ArgumentError) { Prime::QuadraticClassGroup.new(7) }
    assert_match(/negative/, e1.message)
    e2 = assert_raise(ArgumentError) { Prime::QuadraticClassGroup.new("-23") }
    assert_match(/integer/, e2.message)
    e3 = assert_raise(ArgumentError) { Prime::QuadraticClassGroup.new(-14) }
    assert_match(/modulo 4/, e3.message)
    e4 = assert_raise(ArgumentError) { Prime::QuadraticClassGroup.new(-36) }
    assert_match(%r{-36/4 = -9}, e4.message)
    assert_match(/not squarefree/, e4.message)
    e5 = assert_raise(ArgumentError) { Prime::QuadraticClassGroup.new(-32) }
    assert_match(%r{-32/4 = -8}, e5.message)
    assert_match(/modulo 4/, e5.message)
  end

  KNOWN_CLASS_NUMBERS = {
    -3   => 1,
    -4   => 1,
    -7   => 1,
    -8   => 1,
    -11  => 1,
    -15  => 2,
    -19  => 1,
    -20  => 2,
    -23  => 3,
    -24  => 2,
    -31  => 3,
    -35  => 2,
    -39  => 4,
    -40  => 2,
    -43  => 1,
    -47  => 5,
    -51  => 2,
    -52  => 2,
    -55  => 4,
    -56  => 4,
    -59  => 3,
    -67  => 1,
    -68  => 4,
    -71  => 7,
    -84  => 4,
    -87  => 6,
    -163 => 1,
    -707 => 6,
  }

  KNOWN_REDUCED_FORMS = {
    -15  => [[1, 1, 4], [2, 1, 2]],
    -20  => [[1, 0, 5], [2, 2, 3]],
    -23  => [[1, 1, 6], [2, -1, 3], [2, 1, 3]],
    -35  => [[1, 1, 9], [3, 1, 3]],
    -84  => [[1, 0, 21], [2, 2, 11], [3, 0, 7], [5, 4, 5]],
  }

  def test_known_class_numbers_and_forms
    KNOWN_CLASS_NUMBERS.each do |d, h|
      group = Prime::QuadraticClassGroup.new(d)
      assert_equal(h, group.class_number, "h(#{d})")
      assert_equal(h, group.forms.size)
      assert_equal(group.forms, group.to_a.sort)
      group.forms.each do |f|
        assert_equal(d, f.discriminant)
        a, b, c = f.to_a
        assert(b.abs <= a && a <= c)
        assert(!(b.abs == a && b < 0))
        assert(!(a == c && b < 0))
      end
    end
    KNOWN_REDUCED_FORMS.each do |d, expected|
      group = Prime::QuadraticClassGroup.new(d)
      assert_equal(expected, group.forms.map(&:to_a), "forms of #{d}")
    end
  end

  def test_group_axioms
    KNOWN_CLASS_NUMBERS.each_key do |d|
      group = Prime::QuadraticClassGroup.new(d)
      id = group.identity
      assert_equal([1, d.odd? ? 1 : 0, d.odd? ? (1 - d) / 4 : -d / 4], id.to_a)
      group.each do |f|
        assert_equal(f, id.compose(f), "id*f for #{d}")
        assert_equal(f, f.compose(id), "f*id for #{d}")
        assert_equal(id, f.compose(f.inverse), "f*f^-1 for #{d}")
        assert_equal(id, f.inverse.compose(f))
        assert_equal(f, f.inverse.inverse)
        group.each do |g|
          assert_equal(f.compose(g), g.compose(f), "commute for #{d}")
          group.each do |h|
            assert_equal((f * g) * h, f * (g * h), "assoc for #{d}")
          end
        end
      end
    end
  end

  def test_power_and_order
    group = Prime::QuadraticClassGroup.new(-23)
    f = group[2, -1, 3]
    assert_equal(3, group.order(f))
    assert_equal(group.identity, f**3)
    assert_equal(group[2, 1, 3], f**2)
    assert_equal(f, f**-2)
    assert_equal(group.identity, f**0)

    g20 = Prime::QuadraticClassGroup.new(-20)[2, 2, 3]
    assert_equal(2, Prime::QuadraticClassGroup.new(-20).order(g20))
    assert_equal(Prime::QuadraticClassGroup.new(-20).identity, g20 * g20)

    g71 = Prime::QuadraticClassGroup.new(-71)
    assert_equal(7, g71.class_number)
    element = g71[2, -1, 9]
    assert_equal(7, g71.order(element))
  end

  def test_reduction_of_non_reduced_forms
    # Equivalent representatives reduce to the unique canonical one.
    d = -23
    group = Prime::QuadraticClassGroup.new(d)
    candidates = [
      [3, 1, 2],     # reduced-equivalent boundary a=c
      [6, 5, 2],
      [2, 5, 6],
    ]
    candidates.each do |a, b, c|
      assert_equal(d, b * b - 4 * a * c)
      ra, rb, rc = Prime::BinaryQuadraticForm.reduce_coefficients(a, b, c, d)
      assert_include(group.forms.map(&:to_a), [ra, rb, rc])
    end
    assert_equal([1, 1, 6],
                 Prime::BinaryQuadraticForm.reduce_coefficients(1, -1, 6, d))
  end

  def test_boundary_sign_convention
    # |b| = a keeps b positive; a = c keeps b non-negative.
    d = -15
    assert_equal([1, 1, 4],
                 Prime::BinaryQuadraticForm.reduce_coefficients(4, 1, 1, d))
    assert_equal([1, 1, 4],
                 Prime::BinaryQuadraticForm.reduce_coefficients(4, -1, 1, d))
    d3 = -3
    assert_equal([1, 1, 1],
                 Prime::BinaryQuadraticForm.reduce_coefficients(1, -1, 1, d3))
    d4 = -4
    assert_equal([1, 0, 1],
                 Prime::BinaryQuadraticForm.reduce_coefficients(1, 2, 2, d4))
  end

  def test_form_constructor_validation
    f = Prime::BinaryQuadraticForm.new(2, 1, 3)
    assert_equal(-23, f.discriminant)
    assert_equal([2, 1, 3], f.to_a)
    assert_equal(true, f == Prime::QuadraticClassGroup.new(-23)[2, 1, 3])

    assert_raise(ArgumentError) { Prime::BinaryQuadraticForm.new(-1, 0, 1) }
    assert_equal(-4, Prime::BinaryQuadraticForm.new(1, 0, 1).discriminant)
    assert_raise(ArgumentError) { Prime::BinaryQuadraticForm.new(2, 2, 4) } # imprimitive gcd2
    e = assert_raise(ArgumentError) { Prime::BinaryQuadraticForm.new(1, 0, -1) }
    assert_match(/negative discriminant/, e.message)
    e2 = assert_raise(ArgumentError) { Prime::BinaryQuadraticForm.new(1, 0, 3) }
    assert_match(/not fundamental/, e2.message)
  end

  def test_cross_discriminant_compose_rejected
    f23 = Prime::QuadraticClassGroup.new(-23)[2, 1, 3]
    f15 = Prime::QuadraticClassGroup.new(-15)[2, 1, 2]
    e = assert_raise(ArgumentError) { f23.compose(f15) }
    assert_match(/different discriminants/, e.message)
  end
end
