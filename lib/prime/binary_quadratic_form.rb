# frozen_string_literal: true

class Prime
  # Primitive positive definite binary quadratic forms of negative
  # discriminant, with Gauss composition and inverse.
  #
  # A binary quadratic form +(a, b, c)+ represents
  #
  #   a*x^2 + b*x*y + c*y^2,
  #
  # whose discriminant is +b^2 - 4*a*c+.  Every form produced by this
  # library is given in its canonical reduced representative:
  #
  #   -|a| < b <= a <= c, with b >= 0 when a == c, and
  #   b > 0 when |b| == a (equivalently b == a).
  #
  # This sign convention selects a unique representative of every proper
  # equivalence class, so equality of classes is just tuple equality.
  #
  # See Prime::QuadraticClassGroup for enumeration of the primitive
  # reduced forms of a fundamental discriminant.
  class BinaryQuadraticForm
    # First coefficient (positive for a negative discriminant).
    attr_reader :a

    # Middle coefficient.
    attr_reader :b

    # Last coefficient.
    attr_reader :c

    # Discriminant +b^2 - 4*a*c+, always negative.
    attr_reader :discriminant
    alias d discriminant

    # Builds the form +(a, b, c)+ with discriminant +b^2-4*a*c+.
    #
    # Raises ArgumentError when the coefficients do not define a primitive
    # positive definite integral binary quadratic form of negative
    # discriminant, or when the discriminant is not fundamental.  Use
    # BinaryQuadraticForm.reduced_form to obtain a form from arbitrary
    # (non-reduced) coefficients sharing the same discriminant.
    def initialize(a, b, c)
      unless [a, b, c].all? { |x| x.is_a?(Integer) }
        raise ArgumentError, "coefficients must be integers, got #{[a, b, c].inspect}"
      end
      if a <= 0
        raise ArgumentError, "expected a positive leading coefficient for a negative discriminant, got a=#{a}"
      end
      d = b * b - 4 * a * c
      if d >= 0
        raise ArgumentError, "expected a negative discriminant, got #{d}"
      end
      unless d % 4 == 0 || d % 4 == 1
        raise ArgumentError, "#{d} is not a quadratic discriminant (it is neither 0 nor 1 modulo 4)"
      end
      unless a.gcd(b).gcd(c) == 1
        raise ArgumentError, "(#{a}, #{b}, #{c}) is not primitive: gcd(a,b,c)=#{a.gcd(b).gcd(c)} > 1"
      end
      unless QuadraticClassGroup.fundamental_discriminant?(d)
        raise ArgumentError, QuadraticClassGroup.non_fundamental_reason(d)
      end
      @a, @b, @c, @discriminant = a, b, c, d
      freeze
    end

    # Returns the canonical reduced representative of +self+'s class.
    #
    # The discriminant and primitivity of a form are preserved by the
    # reduction algorithm (proper equivalence).
    def reduced
      ra, rb, rc = self.class.reduce_coefficients(@a, @b, @c, @discriminant)
      self.class.allocate.tap do |form|
        form.instance_variable_set(:@a, ra)
        form.instance_variable_set(:@b, rb)
        form.instance_variable_set(:@c, rc)
        form.instance_variable_set(:@discriminant, @discriminant)
        form.freeze
      end
    end

    # Reduces +(a,b,c)+ of discriminant +discriminant+ and returns a new form.
    def self.reduced_form(a, b, c)
      new(a, b, c).reduced
    end

    # Gauss composition of two forms of the same discriminant.
    #
    # Returns the canonical reduced representative of the product class.
    # Raises ArgumentError when the discriminants differ.
    def compose(other)
      unless other.is_a?(BinaryQuadraticForm)
        raise ArgumentError, "expected a BinaryQuadraticForm, got #{other.inspect}"
      end
      if discriminant != other.discriminant
        raise ArgumentError,
              "forms have different discriminants (#{discriminant} and #{other.discriminant})"
      end
      f = reduced
      g = other.reduced
      ra, rb, rc = Composition.compose(f.a, f.b, g.a, g.b, discriminant)
      self.class.send(:form_from_reduced, ra, rb, rc, discriminant)
    end

    alias * compose

    # Returns the inverse class +(a, -b, c)+ in canonical reduced form.
    def inverse
      self.class.allocate.tap do |form|
        form.instance_variable_set(:@a, @a)
        form.instance_variable_set(:@b, -@b)
        form.instance_variable_set(:@c, @c)
        form.instance_variable_set(:@discriminant, @discriminant)
        form.freeze
      end.reduced
    end

    # Returns the n-th power under Gauss composition (n may be negative).
    def power(n)
      unless n.is_a?(Integer)
        raise ArgumentError, "expected an integer exponent, got #{n.inspect}"
      end
      group = QuadraticClassGroup.new(discriminant)
      group.power(self, n)
    end

    alias ** power

    # Returns [a, b, c].
    def to_a
      [@a, @b, @c]
    end

    def coefficients
      [@a, @b, @c]
    end

    def ==(other)
      other.is_a?(BinaryQuadraticForm) &&
        discriminant == other.discriminant &&
        reduced.to_a == other.reduced.to_a
    end
    alias eql? ==

    def hash
      reduced_tuple = reduced.to_a
      [BinaryQuadraticForm, @discriminant, reduced_tuple].hash
    end

    def <=>(other)
      return nil unless other.is_a?(BinaryQuadraticForm)
      [discriminant, a, b, c] <=> [other.discriminant, other.a, other.b, other.c]
    end

    include Comparable

    def inspect
      "Prime::BinaryQuadraticForm(#{@a}, #{@b}, #{@c})"
    end
    alias to_s inspect

    # True exactly when +(a,b,c)+ is reduced under the library's
    # canonical sign convention.
    def self.reduced_coefficients?(a, b, c, d)
      return false unless a > 0 && b * b - 4 * a * c == d
      return false unless b.abs <= a && a <= c
      return false if b.abs == a && b < 0
      return false if a == c && b < 0
      true
    end

    # Reduction (Gauss) of an arbitrary positive definite form.
    def self.reduce_coefficients(a, b, c, d)
      loop do
        r = b % (2 * a)
        b = r <= a ? r : r - 2 * a
        c = (b * b - d) / (4 * a)
        if a <= c
          b = 0 if b == -a
          b = -b if a == c && b < 0
          return [a, b, c]
        end
        a, b, c = c, -b, a
      end
    end

    # Builds an already-reduced form without re-running reduction or the
    # fundamental-discriminant check (the caller supplies a fundamental d).
    def self.form_from_reduced(a, b, c, d)
      allocate.tap do |form|
        form.instance_variable_set(:@a, a)
        form.instance_variable_set(:@b, b)
        form.instance_variable_set(:@c, c)
        form.instance_variable_set(:@discriminant, d)
        form.freeze
      end
    end
    private_class_method :form_from_reduced

    # Integer arithmetic for the Gauss composition of two reduced forms.
    module Composition
      module_function

      # omega = (e + sqrt(D))/2, omega^2 = k + e*omega.
      # Ideal of (a,b,c): (a, t + omega), t = (b - e)/2.
      def compose(a1, b1, a2, b2, d)
        e = d.odd? ? 1 : 0
        k = d.odd? ? (d - 1) / 4 : d / 4
        t1 = (b1 - e) / 2
        t2 = (b2 - e) / 2

        vecs = [
          [a1 * a2, 0],
          [a1 * t2, a1],
          [a2 * t1, a2],
          [t1 * t2 + k, t1 + t2 + e],
        ]

        # The four pairwise products span the product ideal, possibly as a
        # proper (content) sublattice. Divide the lattice content until the
        # result represents an integral form of discriminant d.
        loop do
          a3, t, q = hnf(vecs)
          g = a3.gcd(t).gcd(q)
          na = a3 / g
          nt = t / g
          nq = q / g
          if nq == 1
            b3 = (2 * nt + e) % (2 * na)
            b3 -= 2 * na if b3 > na
            b3 = 0 if b3 == -na
            if (b3 * b3 - d) % (4 * na) == 0
              c3 = (b3 * b3 - d) / (4 * na)
              return BinaryQuadraticForm.reduce_coefficients(na, b3, c3, d)
            end
          end
          vecs << [a3 / g, 0]
          vecs << [t / g, q / g]
          raise "Gauss composition failed to produce an integral form" if g == 1
        end
      end

      # Column Hermite normal form of a rank-2 lattice generated by the
      # integer vectors +vecs+, returned as [h11, h12, d0] for the columns
      # (h11,0) and (h12,d0).
      def hnf(vecs)
        d0 = vecs.inject(0) { |g, (_, q)| g.gcd(q) }
        raise "product lattice has rank < 2" if d0 == 0
        u0 = bezout_constant(vecs, d0)
        h11 = vecs.inject(0) { |g, (p, q)| g.gcd((p - (q / d0) * u0).abs) }
        raise "degenerate product lattice" if h11 == 0
        [h11, u0 % h11, d0]
      end

      # Constant component of an integer combination of +vecs+ whose second
      # components sum to +target+ (= gcd of the second components).
      def bezout_constant(vecs, target)
        d = 0
        coeffs = Array.new(vecs.size, 0)
        vecs.each_with_index do |(_, q), i|
          if d == 0
            next if q == 0
            d = q.abs
            coeffs[i] = q.positive? ? 1 : -1
          else
            g, x, y = egcd(d, q.abs)
            sign = q < 0 ? -1 : 1
            coeffs.map! { |c| c * x }
            coeffs[i] = sign * y
            d = g
          end
        end
        raise "bad Bezout combination" unless d == target
        coeffs.each_with_index.sum(0) { |c, i| c * vecs[i][0] }
      end

      def egcd(a, b)
        return [a, 1, 0] if b == 0
        g, x1, y1 = egcd(b, a % b)
        [g, y1, x1 - (a / b) * y1]
      end
    end
  end
end
