# frozen_string_literal: false
require 'test/unit'
require 'prime'

class TestPocklington < Test::Unit::TestCase
  Pocklington = Prime::Pocklington

  # 20123 - 1 = 2 * 10061, and 10061 > SMALL_FACTOR_LIMIT, so its
  # certificate carries one level of sub-certificate.
  SAFE_PRIME = 20123
  SAFE_PRIME_FACTOR = 10061

  # 42359 - 1 = 2 * 21179, 21179 - 1 = 2 * 10589: two levels of
  # recursive sub-certificates.
  CHAIN_PRIME = 42359
  CHAIN_FACTOR_1 = 21179
  CHAIN_FACTOR_2 = 10589

  # 20078802347 - 1 = 2 * 100003 * 100391; both large factors are beyond
  # the generator's trial division reach, so they must be supplied as
  # known factors.
  SEMIPRIME_N = 20078802347
  SEMIPRIME_R1 = 100003
  SEMIPRIME_R2 = 100391

  MERSENNE_127 = 2**127 - 1

  def deep_copy(certificate)
    Marshal.load(Marshal.dump(certificate))
  end

  def generate_proven(n, **kwargs)
    result = Pocklington.generate(n, **kwargs)
    assert_predicate(result, :proven?, "expected #{n} to be certifiable, got: #{result.reason}")
    result.certificate
  end

  def assert_tampered(certificate)
    assert_equal(false, Pocklington.verify(certificate),
                 "tampered certificate must be rejected: #{certificate.inspect}")
  end

  # --- generation -----------------------------------------------------

  def test_generate_small_primes
    [2, 3, 5, 7, 11, 13, 97, 541, 7919].each do |p|
      certificate = generate_proven(p)
      assert_equal(p, certificate[:n])
      assert_equal(true, Pocklington.verify(certificate))
    end
  end

  def test_generate_two_is_trivial_certificate
    certificate = generate_proven(2)
    assert_equal({n: 2, factors: [], witnesses: [], sub_certificates: []}, certificate)
  end

  def test_generate_recursive_sub_certificates
    certificate = generate_proven(CHAIN_PRIME)

    assert_equal([[2, 1], [CHAIN_FACTOR_1, 1]], certificate[:factors])
    assert_equal([CHAIN_FACTOR_1], certificate[:sub_certificates].map(&:first))

    sub = certificate[:sub_certificates].first[1]
    assert_equal(CHAIN_FACTOR_1, sub[:n])
    assert_equal([[2, 1], [CHAIN_FACTOR_2, 1]], sub[:factors])

    subsub = sub[:sub_certificates].first[1]
    assert_equal(CHAIN_FACTOR_2, subsub[:n])
    assert_equal([], subsub[:sub_certificates])

    assert_equal(true, Pocklington.verify(certificate))
  end

  def test_generate_large_prime
    certificate = generate_proven(MERSENNE_127)
    assert_not_empty(certificate[:sub_certificates])
    assert_equal(true, Pocklington.verify(certificate))
  end

  def test_generate_with_known_factors
    # The generator's own trial division cannot reach 100003 and 100391.
    result = Pocklington.generate(SEMIPRIME_N)
    assert_predicate(result, :unproven?)

    certificate = generate_proven(SEMIPRIME_N,
                                  known_factors: [[SEMIPRIME_R1, 1], [SEMIPRIME_R2, 1]])
    assert_equal(true, Pocklington.verify(certificate))
  end

  def test_generate_with_partial_known_factors
    # Pocklington's theorem only needs F >= sqrt(n): one large factor
    # of n-1 is enough here.
    certificate = generate_proven(SEMIPRIME_N, known_factors: [[SEMIPRIME_R1, 1]])
    assert_equal(true, Pocklington.verify(certificate))
  end

  def test_generate_ignores_unusable_known_factors
    # Composite or non-dividing known factors are skipped; the
    # generator's own trial division still certifies 13.
    certificate = generate_proven(13, known_factors: [[4, 1], [7, 1]])
    assert_equal([[2, 2], [3, 1]], certificate[:factors])
    assert_equal(true, Pocklington.verify(certificate))
  end

  def test_generate_rejects_malformed_known_factors
    assert_raise(ArgumentError) { Pocklington.generate(13, known_factors: 7) }
    assert_raise(ArgumentError) { Pocklington.generate(13, known_factors: [["2", 1]]) }
    assert_raise(ArgumentError) { Pocklington.generate(13, known_factors: [[-2, 1]]) }
  end

  # --- unproven is not composite --------------------------------------

  def test_unproven_result_for_composites
    [4, 9, 15, 341, 561, 2047, 41041, 20121].each do |composite|
      result = Pocklington.generate(composite)
      assert_predicate(result, :unproven?, "#{composite} must not get a certificate")
      assert_not_predicate(result, :proven?)
      assert_equal(:unproven, result.status)
      assert_nil(result.certificate)
      assert_kind_of(String, result.reason)
    end
  end

  def test_unproven_result_for_uncertifiable_prime
    # SEMIPRIME_N is prime, but without known factors the generator
    # cannot find enough factors of n-1.  The result must say
    # "unproven", never "composite".
    assert_equal(true, SEMIPRIME_N.prime?)
    result = Pocklington.generate(SEMIPRIME_N)
    assert_equal(:unproven, result.status)
    assert_nil(result.certificate)
    assert_match(/cover/, result.reason)
  end

  def test_unproven_result_for_invalid_input
    [nil, 0, 1, -7, 2.5, "13"].each do |input|
      result = Pocklington.generate(input)
      assert_predicate(result, :unproven?)
      assert_nil(result.certificate)
    end
  end

  # --- verification of genuine certificates ---------------------------

  def test_verify_genuine_certificates
    [SAFE_PRIME, CHAIN_PRIME, SEMIPRIME_N, MERSENNE_127].each do |p|
      kwargs = p == SEMIPRIME_N ? {known_factors: [[SEMIPRIME_R1, 1], [SEMIPRIME_R2, 1]]} : {}
      assert_equal(true, Pocklington.verify(generate_proven(p, **kwargs)))
    end
  end

  def test_certificate_is_plain_serializable_data
    certificate = generate_proven(CHAIN_PRIME)
    assert_equal(true, Pocklington.verify(Marshal.load(Marshal.dump(certificate))))
  end

  # --- tampering: n -----------------------------------------------------

  def test_tamper_n
    certificate = generate_proven(CHAIN_PRIME)

    tampered = deep_copy(certificate)
    tampered[:n] += 2
    assert_tampered(tampered)

    tampered = deep_copy(certificate)
    tampered[:n] = CHAIN_PRIME * 3
    assert_tampered(tampered)

    tampered = deep_copy(certificate)
    tampered[:n] = CHAIN_PRIME - 1 # even
    assert_tampered(tampered)

    tampered = deep_copy(certificate)
    tampered[:n] = "42359"
    assert_tampered(tampered)
  end

  # --- tampering: factorization ---------------------------------------

  def test_tamper_factor_exponent
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    certificate[:factors][1][1] = 2
    assert_tampered(certificate)
  end

  def test_tamper_factor_value
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    certificate[:factors][1][0] += 2
    assert_tampered(certificate)
  end

  def test_tamper_factor_composite
    # 37 - 1 = 36 = 4 * 9: the "factors" divide n-1 and cover sqrt(n),
    # and 2 satisfies both congruences, but 4 and 9 are not prime.
    forged = {
      n: 37,
      factors: [[4, 1], [9, 1]],
      witnesses: [[4, 2], [9, 2]],
      sub_certificates: []
    }
    assert_equal(1, 2.pow(36, 37))
    assert_equal(1, (2.pow(9, 37) - 1).gcd(37))
    assert_equal(1, (2.pow(4, 37) - 1).gcd(37))
    assert_tampered(forged)
  end

  def test_tamper_factor_duplicate
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    certificate[:factors] << [2, 1]
    assert_tampered(certificate)
  end

  def test_tamper_factor_unsorted
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    certificate[:factors].reverse!
    assert_tampered(certificate)
  end

  def test_tamper_insufficient_coverage
    # Dropping the large factor leaves F = 2, far below sqrt(n).
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    certificate[:factors].delete_if { |q, _| q == CHAIN_FACTOR_1 }
    certificate[:witnesses].delete_if { |q, _| q == CHAIN_FACTOR_1 }
    certificate[:sub_certificates].clear
    assert_tampered(certificate)
  end

  # --- tampering: witnesses -------------------------------------------

  def test_tamper_witness_out_of_range
    certificate = generate_proven(CHAIN_PRIME)
    [0, 1, -3, CHAIN_PRIME, CHAIN_PRIME + 5].each do |a|
      tampered = deep_copy(certificate)
      tampered[:witnesses][0][1] = a
      assert_tampered(tampered)
    end
  end

  def test_tamper_witness_invalid_base
    certificate = generate_proven(CHAIN_PRIME)
    n = CHAIN_PRIME
    # n-1 passes the range check and Fermat's congruence, but is not a
    # valid Pocklington witness for the large factor.
    a = n - 1
    assert_equal(1, a.pow(n - 1, n))
    assert_not_equal(1, (a.pow((n - 1) / CHAIN_FACTOR_1, n) - 1).gcd(n))

    tampered = deep_copy(certificate)
    tampered[:witnesses].each { |entry| entry[1] = a }
    assert_tampered(tampered)
  end

  def test_tamper_witness_removed
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    certificate[:witnesses].shift
    assert_tampered(certificate)
  end

  def test_tamper_witness_duplicated
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    certificate[:witnesses] << certificate[:witnesses].first.map(&:dup)
    assert_tampered(certificate)
  end

  def test_tamper_witness_for_unknown_factor
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    certificate[:witnesses][0][0] = 3
    assert_tampered(certificate)
  end

  # --- tampering: sub-certificates ------------------------------------

  def test_tamper_sub_certificate_removed
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    certificate[:sub_certificates].clear
    assert_tampered(certificate)
  end

  def test_tamper_sub_certificate_binding
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    certificate[:sub_certificates][0][1][:n] += 2
    assert_tampered(certificate)
  end

  def test_tamper_sub_certificate_swapped
    # A genuine certificate for a *different* prime must not be
    # accepted as the proof of this certificate's factor.
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    other = generate_proven(SAFE_PRIME)
    certificate[:sub_certificates][0][1] = other
    assert_tampered(certificate)
  end

  def test_tamper_sub_certificate_inner_witness
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    certificate[:sub_certificates][0][1][:witnesses][0][1] = 1
    assert_tampered(certificate)
  end

  def test_tamper_sub_certificate_for_unknown_factor
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    spare = generate_proven(SAFE_PRIME)
    certificate[:sub_certificates] << [SAFE_PRIME_FACTOR, spare[:sub_certificates].first[1]]
    assert_tampered(certificate)
  end

  def test_tamper_cyclic_reference
    # A certificate containing itself must be rejected, not loop.
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    certificate[:sub_certificates] = [[CHAIN_FACTOR_1, certificate]]
    assert_tampered(certificate)

    # Mutual references must be rejected as well.
    certificate = deep_copy(generate_proven(CHAIN_PRIME))
    sub = certificate[:sub_certificates][0][1]
    sub[:sub_certificates] << [CHAIN_FACTOR_1, certificate]
    assert_tampered(certificate)
  end

  # --- malformed certificates -----------------------------------------

  def test_verify_malformed_certificates
    assert_equal(false, Pocklington.verify(nil))
    assert_equal(false, Pocklington.verify(42))
    assert_equal(false, Pocklington.verify("certificate"))
    assert_equal(false, Pocklington.verify({}))
    assert_equal(false, Pocklington.verify({n: CHAIN_PRIME}))
    assert_equal(false, Pocklington.verify({n: 2, factors: [[2, 1]],
                                            witnesses: [], sub_certificates: []}))
    assert_equal(false, Pocklington.verify({n: 3, factors: [],
                                            witnesses: [], sub_certificates: []}))
  end

  # --- verifier independence ------------------------------------------

  def test_verifier_does_not_cache_results
    certificate = generate_proven(CHAIN_PRIME)

    3.times do
      assert_equal(true, Pocklington.verify(certificate))

      tampered = deep_copy(certificate)
      tampered[:witnesses][0][1] = 1
      assert_equal(false, Pocklington.verify(tampered),
                   "verifier must not rely on a previous positive verdict")

      assert_equal(true, Pocklington.verify(certificate))
    end
  end

  def test_verifier_does_not_trust_generation_side
    # Generation may have populated prime tables and caches; a forged
    # certificate for the same n must still be rejected.
    certificate = generate_proven(SEMIPRIME_N,
                                  known_factors: [[SEMIPRIME_R1, 1], [SEMIPRIME_R2, 1]])
    assert_equal(true, Pocklington.verify(certificate))

    forged = deep_copy(certificate)
    forged[:factors][1][1] += 1
    assert_equal(false, Pocklington.verify(forged))

    forged = deep_copy(certificate)
    forged[:sub_certificates][0][1][:factors][0][1] += 1
    assert_equal(false, Pocklington.verify(forged))
  end
end
