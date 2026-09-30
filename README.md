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

# Batch Euler totient phi and Möbius mu for a narrow interval.
# Values are generated in blocks; no table up to the interval end is built.
Prime.each_phi_and_mu(1_000_000..1_000_010, block_size: 4).to_a
#=> [[1000000, 400000, 0], [1000001, 969000, 1], ...]

Prime.each_phi(1..10).to_a  #=> [[1, 1], [2, 1], ..., [10, 4]]
Prime.each_mu(1..10).to_a   #=> [[1, 1], [2, -1], ..., [10, 1]]
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/prime.

## License

The gem is available as open source under the terms of the [BSD-2-Clause](LICENSE.txt).
