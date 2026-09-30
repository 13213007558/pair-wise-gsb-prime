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

# Euler's totient and the Möbius function over an interval, computed with
# a segmented sieve: only the primes up to the square root of the interval
# end and one segment are kept in memory, so the interval may start very
# large.  The optional segment_size keyword only affects memory and speed,
# never the output.
Prime.each_totient(1, 6).to_a       #=> [[1, 1], [2, 1], [3, 2], [4, 2], [5, 4], [6, 2]]
Prime.each_mobius(1, 6).to_a        #=> [[1, 1], [2, -1], [3, -1], [4, 0], [5, -1], [6, 1]]
Prime.each_totient(10**12, 10**12).to_a  #=> [[1000000000000, 400000000000]]
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/prime.

## License

The gem is available as open source under the terms of the [BSD-2-Clause](LICENSE.txt).
