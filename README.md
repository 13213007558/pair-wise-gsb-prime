# Prime

[![CI](https://github.com/ruby/prime/actions/workflows/test.yml/badge.svg)](https://github.com/ruby/prime/actions/workflows/test.yml)

Prime numbers and factorization library.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'prime'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install prime

## Usage

```ruby
require 'prime'

# Prime is the set of all prime numbers, and it is Enumerable.
Prime.take(4)             #=> [2, 3, 5, 7]
Prime.first(4)            #=> [2, 3, 5, 7]
Prime.each(7).to_a        #=> [2, 3, 5, 7]

# Determining whether an arbitrary integer is a prime number
Prime.prime?(7)           #=> true
8.prime?                  #=> false

# Factorization in prime numbers
Prime.prime_division(8959)                          #=> [[17, 2], [31, 1]]
Prime.int_from_prime_division([[17, 2], [31, 1]])   #=> 8959
17**2 * 31                                          #=> 8959
```

## Pocklington primality certificates

When one party has found a large prime, it can prove its primality to
anyone else with a Pocklington certificate.  The verifier only needs the
certificate data: it neither trusts the prover nor repeats the expensive
search.

```ruby
require 'prime'

# The prover may pass known prime factors of n-1 to speed things up.
result = Prime::Pocklington.generate(20123)
result.proven?        #=> true
result.certificate    #=> {n: 20123, factors: [[2, 1], [10061, 1]], ...}

# The verifier checks the certificate independently.
Prime::Pocklington.verify(result.certificate)   #=> true

# Failing to build a certificate does NOT mean the number is composite.
result = Prime::Pocklington.generate(20078802347)
result.unproven?      #=> true
result.reason         #=> "known factors of 20078802347-1 only cover 2, ..."
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/prime.

## License

The gem is available as open source under the terms of the [BSD-2-Clause](LICENSE.txt).
