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

  # Generates a Pocklington primality certificate for +value+.
  #
  # The certificate contains only integer data and recursively certificates
  # every prime factor used from +value - 1+. When +known_factors+ is nil,
  # the generator is used to factor +value - 1+. When it is an array, it is
  # interpreted as a known partial factorization and no additional factor
  # search is performed.
  #
  # Known factor entries are +[prime, exponent]+ or
  # +[prime, exponent, child_known_factors]+. The third form supplies a
  # known partial factorization of +prime - 1+ for recursive certificate
  # generation.
  #
  # Returns Prime::Pocklington::UNPROVED if no certificate can be produced.
  # That status does not assert that +value+ is composite.
  def pocklington_certificate(value, known_factors = nil, generator = Prime::Generator23.new)
    Pocklington.certificate(value, known_factors, generator)
  end

  # Returns true if +certificate+ is a self-contained, valid Pocklington
  # certificate. This method does not use Prime#prime?, Integer#prime?, or any
  # result retained while the certificate was generated.
  def valid_pocklington_certificate?(certificate)
    Pocklington.valid?(certificate)
  end

  # Pocklington primality certificates.
  #
  # A certificate for a prime +n+ contains a sufficiently large product +F+
  # of certified prime powers dividing +n - 1+, together with a witness +a+
  # satisfying the Pocklington congruences. Certificates are plain Hashes
  # containing integers and Arrays, so they can be marshalled or otherwise
  # transmitted independently of the process that generated them.
  class Pocklington
    UNPROVED = :unproved

    BASE_CERTIFICATES = [2, 3].freeze
    private_constant :BASE_CERTIFICATES

    CERTIFICATE_KEYS = [:prime, :factors, :witness].freeze
    BASE_CERTIFICATE_KEYS = [:prime].freeze
    private_constant :CERTIFICATE_KEYS, :BASE_CERTIFICATE_KEYS

    WITNESS_SEARCH_LIMIT = 100
    private_constant :WITNESS_SEARCH_LIMIT

    MAXIMUM_CERTIFICATE_DEPTH = 10_000
    private_constant :MAXIMUM_CERTIFICATE_DEPTH

    MAXIMUM_FACTOR_COUNT = 10_000
    private_constant :MAXIMUM_FACTOR_COUNT

    class << self
      # Returns a certificate for +n+, or UNPROVED if one cannot be made.
      def certificate(n, known_factors = nil, generator = Prime::Generator23.new)
        raise ArgumentError, "Expected an integer, got #{n}" unless n.is_a?(Integer)
        raise ArgumentError, "Expected a prime generator, got #{generator}" unless generator.respond_to?(:each)
        build_certificate(n, known_factors, generator)
      end

      # Independently verifies a certificate without primality tests or caches.
      def valid?(certificate)
        verify_certificate(certificate, {}, 0)
      rescue StandardError, SystemStackError
        false
      end

      private

      def build_certificate(n, known_factors, generator)
        return UNPROVED unless n >= 2
        return {prime: n} if BASE_CERTIFICATES.include?(n)
        return UNPROVED if n.even?

        factors =
          if known_factors.nil?
            factorize_for_certificate(n - 1, generator.class.new)
          else
            normalize_known_factors(known_factors)
          end

        return UNPROVED if factors.empty?

        n_minus_one = n - 1
        product = 1
        certified_factors = []

        factors.sort_by(&:first).each do |prime, exponent, child_factors|
          break if product * product > n

          return UNPROVED unless prime.is_a?(Integer) && exponent.is_a?(Integer)
          return UNPROVED unless prime >= 2 && prime < n
          return UNPROVED unless exponent >= 1 && exponent <= n_minus_one.abs.bit_length

          power = bounded_power(prime, exponent, n_minus_one)
          return UNPROVED unless power
          product = bounded_multiply(product, power, n_minus_one)
          return UNPROVED unless product && n_minus_one % product == 0

          child_certificate = build_certificate(prime, child_factors, generator.class.new)
          return UNPROVED if child_certificate == UNPROVED

          certified_factors << [prime, exponent, child_certificate]
        end

        return UNPROVED unless product * product > n

        witness = find_witness(n, product, certified_factors.map(&:first))
        return UNPROVED unless witness

        generated = {prime: n, factors: certified_factors, witness: witness}
        valid?(generated) ? generated : UNPROVED
      end

      def normalize_known_factors(known_factors)
        raise ArgumentError, "Expected an array of known factors" unless known_factors.is_a?(Array)

        factors = {}
        known_factors.each do |entry|
          raise ArgumentError, "Expected [prime, exponent] or [prime, exponent, factors]" unless entry.is_a?(Array) && entry.size.between?(2, 3)

          prime, exponent, child_factors = entry
          raise ArgumentError, "Expected an integer prime factor" unless prime.is_a?(Integer)
          raise ArgumentError, "Expected a positive integer exponent" unless exponent.is_a?(Integer) && exponent >= 1
          if entry.size == 3 && !(child_factors.nil? || child_factors.is_a?(Array))
            raise ArgumentError, "Expected known child factors to be an array or nil"
          end
          raise ArgumentError, "Duplicate known factor #{prime}" if factors.key?(prime)

          factors[prime] = [exponent, child_factors]
        end

        factors.map { |prime, (exponent, child_factors)| [prime, exponent, child_factors] }
      end

      def factorize_for_certificate(value, generator)
        factors = []
        generator.each do |candidate|
          break if candidate * candidate > value

          exponent = 0
          while value % candidate == 0
            value /= candidate
            exponent += 1
          end
          factors << [candidate, exponent, nil] if exponent > 0
          break if value == 1
        end
        factors << [value, 1, nil] if value > 1
        factors
      end

      def bounded_power(base, exponent, limit)
        power = 1
        squared = base
        while exponent > 0
          if exponent.odd?
            power *= squared
            return nil if power > limit
          end
          exponent >>= 1
          if exponent > 0
            squared *= squared
            return nil if squared > limit
          end
        end
        power
      end

      def bounded_multiply(left, right, limit)
        product = left * right
        product <= limit ? product : nil
      end

      def find_witness(n, product, factor_primes)
        n_minus_one = n - 1
        upper_bound = [n - 2, WITNESS_SEARCH_LIMIT].min

        (2..upper_bound).each do |witness|
          next unless witness.gcd(n) == 1
          next unless witness.pow(n_minus_one, n) == 1

          next unless factor_primes.all? do |prime|
            value = witness.pow(n_minus_one / prime, n)
            (value - 1).gcd(n) == 1
          end

          return witness if product * product > n
        end

        nil
      end

      def verify_certificate(certificate, active, depth)
        return false unless certificate.is_a?(Hash)
        return false if depth > MAXIMUM_CERTIFICATE_DEPTH
        n = certificate[:prime]
        return false unless n.is_a?(Integer)

        if BASE_CERTIFICATES.include?(n)
          return certificate.keys.sort == BASE_CERTIFICATE_KEYS.sort
        end

        return false unless n > 3
        return false if active.key?(n)

        active[n] = true
        begin
          verify_non_base_certificate(certificate, n, active, depth)
        ensure
          active.delete(n)
        end
      end

      def verify_non_base_certificate(certificate, n, active, depth)
        return false unless certificate.keys.sort == CERTIFICATE_KEYS.sort

        factors = certificate[:factors]
        witness = certificate[:witness]
        n_minus_one = n - 1

        return false unless factors.is_a?(Array) && !factors.empty? && factors.size <= MAXIMUM_FACTOR_COUNT
        return false unless witness.is_a?(Integer) && witness >= 2 && witness <= n - 2

        product = 1
        seen = {}

        factors.each do |entry|
          return false unless entry.is_a?(Array) && entry.size == 3
          prime, exponent, child_certificate = entry

          return false unless prime.is_a?(Integer) && exponent.is_a?(Integer)
          return false unless child_certificate.is_a?(Hash)
          return false unless prime >= 2 && prime < n
          return false unless exponent >= 1 && exponent <= n_minus_one.bit_length
          return false if seen.key?(prime)
          return false unless verify_certificate(child_certificate, active, depth + 1)
          return false unless child_certificate[:prime] == prime

          seen[prime] = true
          power = bounded_power(prime, exponent, n_minus_one)
          return false unless power
          product = bounded_multiply(product, power, n_minus_one)
          return false unless product && n_minus_one % product == 0
        end

        return false unless product * product > n
        return false unless witness.pow(n_minus_one, n) == 1

        factors.each do |prime, exponent, _|
          value = witness.pow(n_minus_one / prime, n)
          return false unless (value - 1).gcd(n) == 1
        end

        true
      end
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
