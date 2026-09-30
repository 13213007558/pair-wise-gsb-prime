# frozen_string_literal: false
#
# = prime.rb
#
# Prime numbers and factorization library.
#
# Copyright::
#   Copyright (c) 1998-2008 Keiju ISHITSUKA(SHL Japan Inc.)
#   Copyright (c) 2008 Yuki Sonoda (Yugui) <yugui@yugui.jp>
#
# Documentation::
#   Yuki Sonoda
#

require "singleton"
require "forwardable"

class Integer
  # Re-composes a prime factorization and returns the product.
  #
  # See Prime#int_from_prime_division for more details.
  def Integer.from_prime_division(pd)
    Prime.int_from_prime_division(pd)
  end

  # Returns the factorization of +self+.
  #
  # See Prime#prime_division for more details.
  def prime_division(generator = Prime::Generator23.new)
    Prime.prime_division(self, generator)
  end

  # Returns true if +self+ is a prime number, else returns false.
  # Not recommended for very big integers (> 10**23).
  def prime?
    return self >= 2 if self <= 3

    if (bases = miller_rabin_bases)
      return miller_rabin_test(bases)
    end

    return true if self == 5
    return false unless 30.gcd(self) == 1
    (7..Integer.sqrt(self)).step(30) do |p|
      return false if
        self%(p)    == 0 || self%(p+4)  == 0 || self%(p+6)  == 0 || self%(p+10) == 0 ||
        self%(p+12) == 0 || self%(p+16) == 0 || self%(p+22) == 0 || self%(p+24) == 0
    end
    true
  end

  MILLER_RABIN_BASES = [
    [2],
    [2,3],
    [31,73],
    [2,3,5],
    [2,3,5,7],
    [2,7,61],
    [2,13,23,1662803],
    [2,3,5,7,11],
    [2,3,5,7,11,13],
    [2,3,5,7,11,13,17],
    [2,3,5,7,11,13,17,19,23],
    [2,3,5,7,11,13,17,19,23,29,31,37],
    [2,3,5,7,11,13,17,19,23,29,31,37,41],
  ].map!(&:freeze).freeze
  private_constant :MILLER_RABIN_BASES

  private def miller_rabin_bases
    # Miller-Rabin's complexity is O(k log^3n).
    # So we can reduce the complexity by reducing the number of bases tested.
    # Using values from https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test
    i = case
    when self < 0xffff                            then
      # For small integers, Miller Rabin can be slower
      # There is no mathematical significance to 0xffff
      return nil
  # when self < 2_047                             then 0
    when self < 1_373_653                         then 1
    when self < 9_080_191                         then 2
    when self < 25_326_001                        then 3
    when self < 3_215_031_751                     then 4
    when self < 4_759_123_141                     then 5
    when self < 1_122_004_669_633                 then 6
    when self < 2_152_302_898_747                 then 7
    when self < 3_474_749_660_383                 then 8
    when self < 341_550_071_728_321               then 9
    when self < 3_825_123_056_546_413_051         then 10
    when self < 318_665_857_834_031_151_167_461   then 11
    when self < 3_317_044_064_679_887_385_961_981 then 12
    else return nil
    end
    MILLER_RABIN_BASES[i]
  end

  private def miller_rabin_test(bases)
    return false if even?

    r = 0
    d = self >> 1
    while d.even?
      d >>= 1
      r += 1
    end

    self_minus_1 = self-1
    bases.each do |a|
      x = a.pow(d, self)
      next if x == 1 || x == self_minus_1 || a == self

      return false if r.times do
        x = x.pow(2, self)
        break if x == self_minus_1
      end
    end
    true
  end

  # Iterates the given block over all prime numbers.
  #
  # See +Prime+#each for more details.
  def Integer.each_prime(ubound, &block) # :yields: prime
    Prime.each(ubound, &block)
  end
end

#
# The set of all prime numbers.
#
# == Example
#
#   Prime.each(100) do |prime|
#     p prime  #=> 2, 3, 5, 7, 11, ...., 97
#   end
#
# Prime is Enumerable:
#
#   Prime.first 5 # => [2, 3, 5, 7, 11]
#
# == Retrieving the instance
#
# For convenience, each instance method of +Prime+.instance can be accessed
# as a class method of +Prime+.
#
# e.g.
#   Prime.instance.prime?(2)  #=> true
#   Prime.prime?(2)           #=> true
#
# == Generators
#
# A "generator" provides an implementation of enumerating pseudo-prime
# numbers and it remembers the position of enumeration and upper bound.
# Furthermore, it is an external iterator of prime enumeration which is
# compatible with an Enumerator.
#
# +Prime+::+PseudoPrimeGenerator+ is the base class for generators.
# There are few implementations of generator.
#
# [+Prime+::+EratosthenesGenerator+]
#   Uses Eratosthenes' sieve.
# [+Prime+::+TrialDivisionGenerator+]
#   Uses the trial division method.
# [+Prime+::+Generator23+]
#   Generates all positive integers which are not divisible by either 2 or 3.
#   This sequence is very bad as a pseudo-prime sequence. But this
#   is faster and uses much less memory than the other generators. So,
#   it is suitable for factorizing an integer which is not large but
#   has many prime factors. e.g. for Prime#prime? .

class Prime

  VERSION = "0.1.4"

  include Enumerable
  include Singleton

  # Raised when a discrete logarithm subproblem cannot be solved within
  # its memory or work budget.  See Prime#discrete_log.
  class DiscreteLogBudgetExceeded < StandardError; end

  class << self
    extend Forwardable
    include Enumerable

    def method_added(method) # :nodoc:
      (class<< self;self;end).def_delegator :instance, method
    end
  end

  # Iterates the given block over all prime numbers.
  #
  # == Parameters
  #
  # +ubound+::
  #   Optional. An arbitrary positive number.
  #   The upper bound of enumeration. The method enumerates
  #   prime numbers infinitely if +ubound+ is nil.
  # +generator+::
  #   Optional. An implementation of pseudo-prime generator.
  #
  # == Return value
  #
  # An evaluated value of the given block at the last time.
  # Or an enumerator which is compatible to an +Enumerator+
  # if no block given.
  #
  # == Description
  #
  # Calls +block+ once for each prime number, passing the prime as
  # a parameter.
  #
  # +ubound+::
  #   Upper bound of prime numbers. The iterator stops after it
  #   yields all prime numbers p <= +ubound+.
  #
  def each(ubound = nil, generator = EratosthenesGenerator.new, &block)
    generator.upper_bound = ubound
    generator.each(&block)
  end

  # Returns true if +obj+ is an Integer and is prime.  Also returns
  # true if +obj+ is a Module that is an ancestor of +Prime+.
  # Otherwise returns false.
  def include?(obj)
    case obj
    when Integer
      prime?(obj)
    when Module
      Module.instance_method(:include?).bind(Prime).call(obj)
    else
      false
    end
  end

  # Returns true if +value+ is a prime number, else returns false.
  # Integer#prime? is much more performant.
  #
  # == Parameters
  #
  # +value+:: an arbitrary integer to be checked.
  # +generator+:: optional. A pseudo-prime generator.
  def prime?(value, generator = Prime::Generator23.new)
    raise ArgumentError, "Expected a prime generator, got #{generator}" unless generator.respond_to? :each
    raise ArgumentError, "Expected an integer, got #{value}" unless value.respond_to?(:integer?) && value.integer?
    return false if value < 2
    generator.each do |num|
      q,r = value.divmod num
      return true if q < num
      return false if r == 0
    end
  end

  # Re-composes a prime factorization and returns the product.
  #
  # For the decomposition:
  #
  #   [[p_1, e_1], [p_2, e_2], ..., [p_n, e_n]],
  #
  # it returns:
  #
  #   p_1**e_1 * p_2**e_2 * ... * p_n**e_n.
  #
  # == Parameters
  # +pd+:: Array of pairs of integers.
  #        Each pair consists of a prime number -- a prime factor --
  #        and a natural number -- its exponent (multiplicity).
  #
  # == Example
  #   Prime.int_from_prime_division([[3, 2], [5, 1]])  #=> 45
  #   3**2 * 5                                         #=> 45
  #
  def int_from_prime_division(pd)
    pd.inject(1){|value, (prime, index)|
      value * prime**index
    }
  end

  # Returns the factorization of +value+.
  #
  # For an arbitrary integer:
  #
  #   p_1**e_1 * p_2**e_2 * ... * p_n**e_n,
  #
  # prime_division returns an array of pairs of integers:
  #
  #   [[p_1, e_1], [p_2, e_2], ..., [p_n, e_n]].
  #
  # Each pair consists of a prime number -- a prime factor --
  # and a natural number -- its exponent (multiplicity).
  #
  # == Parameters
  # +value+:: An arbitrary integer.
  # +generator+:: Optional. A pseudo-prime generator.
  #               +generator+.succ must return the next
  #               pseudo-prime number in ascending order.
  #               It must generate all prime numbers,
  #               but may also generate non-prime numbers, too.
  #
  # === Exceptions
  # +ZeroDivisionError+:: when +value+ is zero.
  #
  # == Example
  #
  #   Prime.prime_division(45)  #=> [[3, 2], [5, 1]]
  #   3**2 * 5                  #=> 45
  #
  def prime_division(value, generator = Prime::Generator23.new)
    raise ZeroDivisionError if value == 0
    if value < 0
      value = -value
      pv = [[-1, 1]]
    else
      pv = []
    end
    generator.each do |prime|
      count = 0
      while (value1, mod = value.divmod(prime)
             mod) == 0
        value = value1
        count += 1
      end
      if count != 0
        pv.push [prime, count]
      end
      break if value1 <= prime
    end
    if value > 1
      pv.push [value, 1]
    end
    pv
  end

  # Solves the discrete logarithm problem modulo a prime +p+:
  #
  #   g**x ≡ h (mod p)
  #
  # +g+ does not need to be a primitive root.  On success the method
  # returns the pair <code>[x, ord]</code>, where +ord+ is the
  # multiplicative order of +g+ modulo +p+ and +x+ is the least
  # non-negative representative of the solution congruence class: an
  # integer solves the equation exactly when it is congruent to +x+
  # modulo +ord+.
  #
  # Returns +nil+ when +h+ is not in the subgroup generated by +g+,
  # i.e. when the equation has no solution.
  #
  # The factorization of <code>p - 1</code> is used to reduce the
  # problem to one subproblem per prime power dividing the order of
  # +g+ (Pohlig-Hellman), which is efficient while the order is
  # smooth.  Each remaining subproblem is solved by an independent
  # baby-step giant-step search with its own budget:
  #
  # +max_table_size+::
  #   Maximum number of entries of the baby-step table of a single
  #   subproblem (memory budget).
  # +max_steps+::
  #   Maximum number of group operations of a single subproblem
  #   (work budget).
  #
  # == Exceptions
  # +ArgumentError+:: when +p+ is not a prime, or +g+ or +h+ is zero
  #                   modulo +p+.
  # +Prime::DiscreteLogBudgetExceeded+:: when a subproblem exceeds
  #                   +max_table_size+ or +max_steps+.  This is
  #                   distinct from the +nil+ returned when the
  #                   equation has no solution.
  #
  # == Example
  #   Prime.discrete_log(5, 3, 23)   #=> [16, 22]: 5**16 % 23 == 3, ord(5) == 22
  #   Prime.discrete_log(3, 9, 13)   #=> [2, 3]: 3 is not a primitive root mod 13
  #   Prime.discrete_log(3, 2, 13)   #=> nil: 2 is not a power of 3 mod 13
  #
  def discrete_log(g, h, p, max_table_size: 1_000_000, max_steps: 10_000_000)
    raise ArgumentError, "Expected an integer modulus, got #{p.inspect}" unless p.is_a?(Integer)
    raise ArgumentError, "Expected a prime modulus, got #{p}" unless p >= 2 && p.prime?
    raise ArgumentError, "Expected an integer base, got #{g.inspect}" unless g.is_a?(Integer)
    raise ArgumentError, "Expected an integer value, got #{h.inspect}" unless h.is_a?(Integer)
    raise ArgumentError, "Expected a positive memory budget, got #{max_table_size}" unless max_table_size.is_a?(Integer) && max_table_size >= 1
    raise ArgumentError, "Expected a positive work budget, got #{max_steps}" unless max_steps.is_a?(Integer) && max_steps >= 1
    g %= p
    h %= p
    raise ArgumentError, "Expected a non-zero base modulo #{p}" if g.zero?
    raise ArgumentError, "Expected a non-zero value modulo #{p}" if h.zero?

    # Multiplicative order of g modulo p, derived from the
    # factorization of p - 1.
    factors = prime_division(p - 1)
    order = p - 1
    factors.each do |q, _|
      order /= q while order % q == 0 && g.pow(order / q, p) == 1
    end

    # (Z/pZ)* is cyclic, so h lies in the subgroup generated by g
    # exactly when the order of h divides the order of g.
    return nil unless h.pow(order, p) == 1

    # Baby-step giant-step search in the subgroup generated by +base+,
    # which must have exactly the given +sub_order+.  Every call is an
    # independent subproblem with its own memory and work budget.
    bsgs = lambda do |base, target, sub_order|
      m = Integer.sqrt(sub_order - 1) + 1
      if m > max_table_size
        raise DiscreteLogBudgetExceeded,
              "subgroup of order #{sub_order} needs a baby-step table of #{m} entries (max_table_size: #{max_table_size})"
      end
      if 2 * m > max_steps
        raise DiscreteLogBudgetExceeded,
              "subgroup of order #{sub_order} needs about #{2 * m} group operations (max_steps: #{max_steps})"
      end
      table = {}
      baby = 1
      m.times do |j|
        table[baby] = j
        baby = baby * base % p
      end
      giant_factor = base.pow(sub_order - m % sub_order, p) # base**-m
      (m + 1).times do |i|
        if (j = table[target])
          break i * m + j
        end
        target = target * giant_factor % p
      end % sub_order
    end

    # Pohlig-Hellman reduction: one independent subproblem per prime
    # power q**e dividing the order of g.
    residues = []
    factors.each do |q, _|
      next if order % q != 0
      qe = q
      qe *= q while order % (qe * q) == 0
      # c and d are the projections of g and h onto the subgroup of
      # order q**e; solve c**x = d (mod p) digit by digit, base q.
      c = g.pow(order / qe, p)
      d = h.pow(order / qe, p)
      base = c.pow(qe / q, p) # generator of the subgroup of order q
      x = 0
      qk = 1
      while qk < qe
        residual = d * c.pow(qe - x, p) % p # d * c**-x
        x += bsgs.call(base, residual.pow(qe / (q * qk), p), q) * qk
        qk *= q
      end
      residues << [x, qe]
    end

    # Merge the congruences x ≡ x_i (mod q_i**e_i) into the solution
    # class modulo the order of g.
    inverse = lambda do |a, m| # modular inverse by the extended Euclidean algorithm
      r0, r1 = a % m, m
      s0, s1 = 1, 0
      until r1.zero?
        quotient = r0 / r1
        r0, r1 = r1, r0 - quotient * r1
        s0, s1 = s1, s0 - quotient * s1
      end
      s0 % m
    end
    x = 0
    modulus = 1
    residues.each do |xi, mi|
      t = (xi - x) % mi * inverse.call(modulus, mi) % mi
      x = (x + modulus * t) % (modulus * mi)
      modulus *= mi
    end
    [x, order]
  end

  # An abstract class for enumerating pseudo-prime numbers.
  #
  # Concrete subclasses should override succ, next, rewind.
  class PseudoPrimeGenerator
    include Enumerable

    def initialize(ubound = nil)
      @ubound = ubound
    end

    def upper_bound=(ubound)
      @ubound = ubound
    end
    def upper_bound
      @ubound
    end

    # returns the next pseudo-prime number, and move the internal
    # position forward.
    #
    # +PseudoPrimeGenerator+#succ raises +NotImplementedError+.
    def succ
      raise NotImplementedError, "need to define `succ'"
    end

    # alias of +succ+.
    def next
      raise NotImplementedError, "need to define `next'"
    end

    # Rewinds the internal position for enumeration.
    #
    # See +Enumerator+#rewind.
    def rewind
      raise NotImplementedError, "need to define `rewind'"
    end

    # Iterates the given block for each prime number.
    def each
      return self.dup unless block_given?
      if @ubound
        last_value = nil
        loop do
          prime = succ
          break last_value if prime > @ubound
          last_value = yield prime
        end
      else
        loop do
          yield succ
        end
      end
    end

    # see +Enumerator+#with_index.
    def with_index(offset = 0, &block)
      return enum_for(:with_index, offset) { Float::INFINITY } unless block
      return each_with_index(&block) if offset == 0

      each do |prime|
        yield prime, offset
        offset += 1
      end
    end

    # see +Enumerator+#with_object.
    def with_object(obj)
      return enum_for(:with_object, obj) { Float::INFINITY } unless block_given?
      each do |prime|
        yield prime, obj
      end
    end

    def size
      Float::INFINITY
    end
  end

  # An implementation of +PseudoPrimeGenerator+.
  #
  # Uses +EratosthenesSieve+.
  class EratosthenesGenerator < PseudoPrimeGenerator
    def initialize
      @last_prime_index = -1
      super
    end

    def succ
      @last_prime_index += 1
      EratosthenesSieve.instance.get_nth_prime(@last_prime_index)
    end
    def rewind
      initialize
    end
    alias next succ
  end

  # An implementation of +PseudoPrimeGenerator+ which uses
  # a prime table generated by trial division.
  class TrialDivisionGenerator < PseudoPrimeGenerator
    def initialize
      @index = -1
      super
    end

    def succ
      TrialDivision.instance[@index += 1]
    end
    def rewind
      initialize
    end
    alias next succ
  end

  # Generates all integers which are greater than 2 and
  # are not divisible by either 2 or 3.
  #
  # This is a pseudo-prime generator, suitable on
  # checking primality of an integer by brute force
  # method.
  class Generator23 < PseudoPrimeGenerator
    def initialize
      @prime = 1
      @step = nil
      super
    end

    def succ
      if (@step)
        @prime += @step
        @step = 6 - @step
      else
        case @prime
        when 1; @prime = 2
        when 2; @prime = 3
        when 3; @prime = 5; @step = 2
        end
      end
      @prime
    end
    alias next succ
    def rewind
      initialize
    end
  end

  # Internal use. An implementation of prime table by trial division method.
  class TrialDivision
    include Singleton

    def initialize # :nodoc:
      # These are included as class variables to cache them for later uses.  If memory
      #   usage is a problem, they can be put in Prime#initialize as instance variables.

      # There must be no primes between @primes[-1] and @next_to_check.
      @primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101]
      # @next_to_check % 6 must be 1.
      @next_to_check = 103            # @primes[-1] - @primes[-1] % 6 + 7
      @ulticheck_index = 3            # @primes.index(@primes.reverse.find {|n|
      #   n < Math.sqrt(@@next_to_check) })
      @ulticheck_next_squared = 121   # @primes[@ulticheck_index + 1] ** 2
    end

    # Returns the +index+th prime number.
    #
    # +index+ is a 0-based index.
    def [](index)
      while index >= @primes.length
        # Only check for prime factors up to the square root of the potential primes,
        #   but without the performance hit of an actual square root calculation.
        if @next_to_check + 4 > @ulticheck_next_squared
          @ulticheck_index += 1
          @ulticheck_next_squared = @primes.at(@ulticheck_index + 1) ** 2
        end
        # Only check numbers congruent to one and five, modulo six. All others

        #   are divisible by two or three.  This also allows us to skip checking against
        #   two and three.
        @primes.push @next_to_check if @primes[2..@ulticheck_index].find {|prime| @next_to_check % prime == 0 }.nil?
        @next_to_check += 4
        @primes.push @next_to_check if @primes[2..@ulticheck_index].find {|prime| @next_to_check % prime == 0 }.nil?
        @next_to_check += 2
      end
      @primes[index]
    end
  end

  # Internal use. An implementation of Eratosthenes' sieve
  class EratosthenesSieve
    include Singleton

    def initialize
      @primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101]
      # @max_checked must be an even number
      @max_checked = @primes.last + 1
    end

    def get_nth_prime(n)
      compute_primes while @primes.size <= n
      @primes[n]
    end

    private
    def compute_primes
      # max_segment_size must be an even number
      max_segment_size = 1e6.to_i
      max_cached_prime = @primes.last
      # do not double count primes if #compute_primes is interrupted
      # by Timeout.timeout
      @max_checked = max_cached_prime + 1 if max_cached_prime > @max_checked

      segment_min = @max_checked
      segment_max = [segment_min + max_segment_size, max_cached_prime * 2].min
      root = Integer.sqrt(segment_max)

      segment = ((segment_min + 1) .. segment_max).step(2).to_a

      (1..Float::INFINITY).each do |sieving|
        prime = @primes[sieving]
        break if prime > root
        composite_index = (-(segment_min + 1 + prime) / 2) % prime
        while composite_index < segment.size do
          segment[composite_index] = nil
          composite_index += prime
        end
      end

      @primes.concat(segment.compact!)

      @max_checked = segment_max
    end
  end
end
