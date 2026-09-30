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

  # Returns the factorization of +self+, which must be a signed 64-bit
  # integer.
  #
  # See Prime#prime_division_int64 for more details.
  def prime_division_int64(random: Random.new, budget: 1_000_000)
    Prime.prime_division_int64(self, random: random, budget: budget)
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

  # The smallest integer for which Prime#prime_int64? and
  # Prime#prime_division_int64 are guaranteed to work.
  INT64_MIN = -(2**63)

  # The largest integer for which Prime#prime_int64? and
  # Prime#prime_division_int64 are guaranteed to work.
  INT64_MAX = 2**63 - 1

  include Enumerable
  include Singleton

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

  # Returns true if +value+ is a prime number, else returns false.
  #
  # +value+ must be a signed 64-bit integer
  # (Prime::INT64_MIN..Prime::INT64_MAX).  Within that range the
  # answer is always exact: it is decided by a deterministic
  # Miller-Rabin test, never by a probabilistic one.  For integers
  # outside the 64-bit range no such guarantee is made here, and a
  # RangeError is raised instead of silently returning a
  # probabilistic answer; use Integer#prime? for those.
  #
  # == Exceptions
  # +ArgumentError+:: when +value+ is not an Integer.
  # +RangeError+:: when +value+ is outside the signed 64-bit range.
  def prime_int64?(value)
    raise ArgumentError, "Expected an integer, got #{value}" unless value.is_a?(Integer)
    unless INT64_MIN <= value && value <= INT64_MAX
      raise RangeError, "#{value} is out of the signed 64-bit range"
    end
    Int64Factorizer.prime?(value)
  end

  # Returns the factorization of +value+, which must be a signed
  # 64-bit integer (Prime::INT64_MIN..Prime::INT64_MAX).
  #
  # This is a fast alternative to #prime_division for that range:
  # besides trial division it uses perfect power detection and
  # Pollard's rho algorithm, so even products of two large primes
  # are factorized quickly.
  #
  # == Parameters
  # +value+:: A signed 64-bit integer.
  # +random+:: Optional.  The random source used by Pollard's rho;
  #            any object responding to +rand(range)+, e.g. an
  #            instance of Random.  Pass <tt>Random.new(seed)</tt>
  #            to make the factorization reproducible.
  # +budget+:: Optional.  The maximum number of Pollard's rho
  #            iterations (modular multiplications) to perform
  #            before giving up.  The default is enough to factor
  #            any signed 64-bit integer with overwhelming
  #            probability.
  #
  # == Return value
  # A Prime::Int64Factorization.  Its +factors+ are the proven
  # prime factors as <tt>[prime, exponent]</tt> pairs, in the same
  # format as #prime_division; when the factorization is complete
  # (+result.complete?+ is true), +result.to_a+ equals
  # Prime.prime_division(value).
  #
  # If the budget is exhausted first, +result.complete?+ is false
  # and +result.remainder+ holds the product of the cofactors that
  # are proven composite but could not be split in time, so the
  # proven factors and the unfactored remainder are always
  # distinguishable.  Either way,
  #
  #   Prime.int_from_prime_division(result.factors) * result.remainder == value
  #
  # Primality of every returned factor (and compositeness of the
  # remainder) is proven, not probabilistic: the Miller-Rabin test
  # used internally is deterministic for the whole 64-bit range.
  #
  # == Exceptions
  # +ZeroDivisionError+:: when +value+ is zero.
  # +ArgumentError+:: when +value+ is not an Integer, or +budget+
  #                   is not a non-negative Integer.
  # +RangeError+:: when +value+ is outside the signed 64-bit range.
  #                Use #prime_division for arbitrary integers; the
  #                guarantees of this method do not apply there.
  #
  # == Example
  #
  #   result = Prime.prime_division_int64(45, random: Random.new(42))
  #   result.complete?  #=> true
  #   result.to_a       #=> [[3, 2], [5, 1]]
  #
  def prime_division_int64(value, random: Random.new, budget: 1_000_000)
    raise ArgumentError, "Expected an integer, got #{value}" unless value.is_a?(Integer)
    raise ZeroDivisionError if value == 0
    unless INT64_MIN <= value && value <= INT64_MAX
      raise RangeError, "#{value} is out of the signed 64-bit range; use #prime_division instead"
    end
    unless budget.is_a?(Integer) && budget >= 0
      raise ArgumentError, "Expected a non-negative integer budget, got #{budget}"
    end
    unless random.respond_to?(:rand)
      raise ArgumentError, "Expected a random number generator, got #{random}"
    end

    factors = []
    if value < 0
      factors << [-1, 1]
      value = -value
    end
    proven, remainder = Int64Factorizer.new(random: random, budget: budget).factorize(value)
    Int64Factorization.new(factors.concat(proven), remainder)
  end

  # The result of Prime#prime_division_int64.
  #
  # It carries the proven prime factors of the requested value and,
  # when the work budget was exhausted before the factorization was
  # complete, the unfactored remainder.
  class Int64Factorization
    include Enumerable

    # The proven prime factors, as an array of
    # <tt>[prime, exponent]</tt> pairs sorted by prime, in the same
    # format as Prime#prime_division.  The primality of every factor
    # is proven, never probabilistic.
    attr_reader :factors

    # The cofactor that was not decomposed into primes, 1 when the
    # factorization is complete.  When it is not 1, it is a product
    # of integers each proven composite, whose factors could not be
    # found within the given budget.
    attr_reader :remainder

    def initialize(factors, remainder) # :nodoc:
      @factors = factors.freeze
      @remainder = remainder
    end

    # Returns true if the factorization is complete, i.e. #factors
    # holds the full prime factorization and #remainder is 1.
    def complete?
      @remainder == 1
    end

    # Iterates over the proven <tt>[prime, exponent]</tt> pairs.
    def each(&block)
      return to_enum(__method__) { @factors.size } unless block_given?
      @factors.each(&block)
    end

    # Returns the proven prime factors as an array of
    # <tt>[prime, exponent]</tt> pairs, compatible with
    # Prime#prime_division and Integer.from_prime_division.
    # Check #complete? to know whether this is the full
    # factorization of the requested value.
    def to_a
      @factors.dup
    end

    # Returns the factorized value, i.e. the product of the proven
    # factors and the remainder.  Always equals the value that was
    # given to Prime#prime_division_int64.
    def to_i
      Prime.int_from_prime_division(@factors) * @remainder
    end

    def ==(other)
      other.is_a?(Int64Factorization) &&
        @factors == other.factors &&
        @remainder == other.remainder
    end
  end

  # Internal use.  Factorizes signed 64-bit integers, combining
  # trial division, a deterministic Miller-Rabin primality test,
  # perfect power detection and Pollard's rho algorithm with
  # Brent's improvement.  The random source and the work budget of
  # the randomized parts are supplied by the caller.
  class Int64Factorizer
    # Small primes used for trial division.
    SMALL_PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41,
                    43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97].freeze

    # Testing against the first twelve prime bases is a deterministic
    # primality test for every n < 3_317_044_064_679_887_385_961_981,
    # which covers the whole unsigned 64-bit range.
    # Using values from https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test
    MILLER_RABIN_BASES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37].freeze

    # Deterministic primality test for 0 <= n < 2**64.
    def self.prime?(n)
      return false if n < 2
      SMALL_PRIMES.each do |p|
        return true if n == p
        return false if n % p == 0
      end
      # n > 97 here, so every base is smaller than n.
      d = n - 1
      r = 0
      while d.even?
        d >>= 1
        r += 1
      end
      MILLER_RABIN_BASES.each do |a|
        x = a.pow(d, n)
        next if x == 1 || x == n - 1
        composite = true
        (r - 1).times do
          x = x.pow(2, n)
          if x == n - 1
            composite = false
            break
          end
        end
        return false if composite
      end
      true
    end

    def initialize(random:, budget:)
      @random = random
      @budget = budget
    end

    # Factorizes n, where 1 <= n < 2**64.  Returns a pair
    # [factors, remainder], where factors is a sorted array of
    # proven [prime, exponent] pairs and remainder is the product
    # of the proven composite cofactors that could not be split
    # within the budget (1 when the factorization is complete).
    def factorize(n)
      counts = Hash.new(0)
      SMALL_PRIMES.each do |p|
        while n % p == 0
          n /= p
          counts[p] += 1
        end
      end
      stack = n > 1 ? [n] : []
      until stack.empty?
        m = stack.pop
        next if m == 1
        if Int64Factorizer.prime?(m)
          counts[m] += 1
        elsif (power = perfect_power(m))
          base, exponent = power
          exponent.times { stack.push(base) }
        elsif (divisor = pollard_rho(m))
          stack.push(divisor, m / divisor)
        else
          # The budget is exhausted; m and whatever is left on the
          # stack become the remainder.
          stack.push(m)
          break
        end
      end
      remainder = 1
      stack.each do |m|
        if Int64Factorizer.prime?(m)
          counts[m] += 1
        else
          remainder *= m
        end
      end
      [counts.map { |prime, exponent| [prime, exponent] }.sort, remainder]
    end

    private

    # If n is a perfect power, returns [base, exponent] with
    # exponent > 1; otherwise returns nil.
    def perfect_power(n)
      2.upto(n.bit_length - 1) do |exponent|
        base = integer_root(n, exponent)
        return [base, exponent] if base**exponent == n
      end
      nil
    end

    # Returns the largest integer r such that r**k <= n.
    def integer_root(n, k)
      lo = 1
      hi = 1 << ((n.bit_length + k - 1) / k)
      while hi - lo > 1
        mid = (lo + hi) / 2
        if mid**k <= n
          lo = mid
        else
          hi = mid
        end
      end
      lo
    end

    # Pollard's rho algorithm with Brent's improvement.  Returns a
    # non-trivial divisor of n, or nil when the budget is exhausted.
    # n must be an odd composite not divisible by any small prime.
    def pollard_rho(n)
      block_size = 128
      until @budget <= 0
        y = @random.rand(1...n)
        c = @random.rand(1...n)
        g = 1
        r = 1
        q = 1
        x = y
        ys = y
        while g == 1
          x = y
          r.times do
            return nil if @budget <= 0
            @budget -= 1
            y = (y * y + c) % n
          end
          k = 0
          while k < r && g == 1
            ys = y
            [block_size, r - k].min.times do
              return nil if @budget <= 0
              @budget -= 1
              y = (y * y + c) % n
              q = q * (x - y).abs % n
            end
            g = n.gcd(q)
            k += block_size
          end
          r <<= 1
        end
        if g == n
          loop do
            return nil if @budget <= 0
            @budget -= 1
            ys = (ys * ys + c) % n
            g = n.gcd((x - ys).abs)
            break if g > 1
          end
          next if g == n # unlucky parameters; retry with fresh ones
        end
        return g
      end
      nil
    end
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
