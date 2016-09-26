# mal

Minuscule (Type) Algebra - a type-matching thing for Ruby.

The library allows you to do simple type matching based on _any_ Ruby types that support the "triqual"
operator (type equality). It is distantly related to libraries like rb_dry_types

A basic building block for these checks can be any object that supports `===`.
For example, to verify that a certain variable is either a String or a Numeric

    Mal.Either(Numeric, String) === "ohai" # => true
    Mal.Either(Numeric, String) === false  # => false

Where this gets interesting is when you use combinations and unions. For instance, you can check if an
Array only contains booleans:

    Mal.ArrayOf(Mal.Either(true, false)) === [true, false, false] #=> true

You can also match Hashes, which lends itself to JSON assertions quite nicely:

    Mal.HashWith(name: String, age: Numeric) === {name: 'Jane', age: 22, accepted_license_agreement: true} #=> true

You can also use these type matchers for case statements:

    case fetch_api_response
    when Mal.HashWith(error: Mal.Anything())
      raise ...
    when Mal.HashWith(inserted: Mal.Boolean())
      # insert successful
    end

## Contributing to mal
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2016 Julik Tarkhanov. See LICENSE.txt for
further details.

