# frozen_string_literal: true

class Prime
  # The ideal class group of the imaginary quadratic order of a negative
  # fundamental discriminant +D+, represented by primitive reduced binary
  # quadratic forms with Gauss composition as multiplication.
  #
  # The reduced representatives share the sign convention documented on
  # Prime::BinaryQuadraticForm:
  #
  #   -|a| < b <= a <= c, b >= 0 when a == c, b == a (never -a) on the
  # boundary |b| == a.
  #
  # Examples:
  #
  #   group = Prime::QuadraticClassGroup.new(-23)
  #   group.class_number      #=> 3
  #   group.identity          #=> Prime::BinaryQuadraticForm(1, 1, 6)
  #   f = group.forms[1]      #=> Prime::BinaryQuadraticForm(2, -1, 3)
  #   f * f                   #=> Prime::BinaryQuadraticForm(2, 1, 3)
  #   f * f.inverse           #=> Prime::BinaryQuadraticForm(1, 1, 6)
  class QuadraticClassGroup
    include Enumerable

    # The negative fundamental discriminant of the class group.
    attr_reader :discriminant
    alias d discriminant

    # Creates the class group of the given negative fundamental
    # discriminant.
    #
    # Raises ArgumentError (with an explanatory message) when +d+ is not a
    # negative fundamental discriminant.
    def initialize(d)
      QuadraticClassGroup.assert_fundamental_discriminant!(d)
      @discriminant = d
      @forms = nil
    end

    # The principal (identity) reduced form.
    def identity
      if @discriminant.odd?
        form(1, 1, (1 - @discriminant) / 4)
      else
        form(1, 0, -@discriminant / 4)
      end
    end
    alias one identity

    # All primitive reduced forms of the discriminant, sorted by
    # [a, b, c].
    def forms
      @forms ||= begin
        bound = Integer.sqrt((-@discriminant) / 3)
        parity = @discriminant % 2
        list = []
        (1..bound).each do |a|
          (-a..a).each do |b|
            next unless b % 2 == parity
            next if b.abs == a && b < 0
            numerator = b * b - @discriminant
            next unless numerator % (4 * a) == 0
            c = numerator / (4 * a)
            next unless c >= a
            next if a == c && b < 0
            list << form(a, b, c)
          end
        end
        list
      end
    end
    alias to_a forms

    # The class number h(D).
    def class_number
      forms.size
    end
    alias size class_number
    alias length class_number

    # Yields each primitive reduced form.
    def each(&block)
      return to_enum(:each) unless block
      forms.each(&block)
      self
    end

    # Returns the reduced form with coefficients [a, b, c], or nil.
    def [](a, b = nil, c = nil)
      target = a.is_a?(Array) ? a : [a, b, c]
      forms.find { |f| f.to_a == target }
    end

    # Gauss composition, returning a canonical reduced form of this group.
    def compose(f, g)
      assert_member!(f)
      assert_member!(g)
      f.compose(g)
    end
    alias multiply compose

    # Inverse class of +f+ within this group.
    def inverse(f)
      assert_member!(f)
      f.inverse
    end

    # Returns the n-th power of +f+ (n may be negative).
    def power(f, n)
      assert_member!(f)
      raise ArgumentError, "expected an integer exponent, got #{n.inspect}" unless n.is_a?(Integer)
      n %= class_number
      result = identity
      base = f.reduced
      while n > 0
        result = result.compose(base) if n.odd?
        base = base.compose(base)
        n >>= 1
      end
      result
    end

    # Multiplicative order of +f+ in the class group.
    def order(f)
      assert_member!(f)
      current = f.reduced
      (1..class_number).each do |n|
        return n if current == identity
        current = current.compose(f.reduced)
      end
    end

    def ==(other)
      other.is_a?(QuadraticClassGroup) && discriminant == other.discriminant
    end
    alias eql? ==

    def hash
      [QuadraticClassGroup, discriminant].hash
    end

    def inspect
      "Prime::QuadraticClassGroup(discriminant=#{@discriminant}, h=#{class_number})"
    end
    alias to_s inspect

    # True iff +d+ is a fundamental discriminant (negative or positive).
    #
    # +d+ is fundamental exactly when either
    # - d = 4*m for a squarefree m with m = 2 or m = 3 (mod 4), or
    # - d is squarefree and d = 1 (mod 4).
    def self.fundamental_discriminant?(d)
      return false unless d.is_a?(Integer) && d != 0 && d != 1
      if d % 4 == 1
        squarefree?(d)
      elsif d % 4 == 0
        m = d / 4
        (m == -1 || m % 4 == 2 || m % 4 == 3) && squarefree?(m)
      else
        false
      end
    end

    # Human-readable explanation of why +d+ is rejected as a fundamental
    # discriminant.
    def self.non_fundamental_reason(d)
      unless d.is_a?(Integer)
        return "expected an integer discriminant, got #{d.inspect}"
      end
      if d >= 0
        return "expected a negative discriminant, got #{d}"
      end
      case d % 4
      when 2, 3
        "#{d} is not a quadratic discriminant: a discriminant must be 0 or 1 modulo 4"
      when 0
        m = d / 4
        if !(m % 4 == 2 || m % 4 == 3)
          "#{d} is not fundamental: #{d}/4 = #{m} must be squarefree and congruent to 2 or 3 modulo 4"
        elsif !squarefree?(m)
          "#{d} is not fundamental: #{d}/4 = #{m} is not squarefree"
        else
          "#{d} is not fundamental"
        end
      else
        if !squarefree?(d)
          "#{d} is not fundamental: discriminants congruent to 1 modulo 4 must be squarefree"
        else
          "#{d} is not fundamental"
        end
      end
    end

    def self.assert_fundamental_discriminant!(d)
      unless d.is_a?(Integer)
        raise ArgumentError, "expected an integer discriminant, got #{d.inspect}"
      end
      if d >= 0
        raise ArgumentError, "expected a negative discriminant, got #{d}"
      end
      unless fundamental_discriminant?(d)
        raise ArgumentError, non_fundamental_reason(d)
      end
    end

    def self.squarefree?(n)
      n = n.abs
      return true if n == 1
      Prime.prime_division(n).all? { |_, exponent| exponent == 1 }
    end

    private

    def form(a, b, c)
      BinaryQuadraticForm.send(:form_from_reduced, a, b, c, @discriminant)
    end

    def assert_member!(f)
      unless f.is_a?(BinaryQuadraticForm)
        raise ArgumentError, "expected a BinaryQuadraticForm, got #{f.inspect}"
      end
      if f.discriminant != @discriminant
        raise ArgumentError,
              "form has discriminant #{f.discriminant}, expected #{@discriminant}"
      end
    end
  end
end
