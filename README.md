# Decorum

Decorum implements lightweight decorators for Ruby, called "tasteful decorators." (See below.)
It is very small, possibly very fast, and has no requirements outside of the standard library.
Use it wherever.

## Quick Start
```ruby
gem install decorum

class BirthdayParty
  include Decorum::Decorations
end

class Confetti < Decorum::Decorator
  def shoot_confetti
    "boom, yay"
  end
end

bp = BirthdayParty.new
bp.respond_to?(:shoot_confetti) # ==> false
bp.decorate(Confetti)
bp.shoot_confetti # ==> "boom, yay"
```

## Rationale

Decorum decorators are in the mold of the traditional, Gang of Four style pattern, with
a few additional conditions. They aren't a subtype of this pattern (for various reasons)
but they agree in the following way: Decorator is a family of basic object oriented 
patterns which (a) are implemented with composition/delegation and (b) respect the original
public interface of the objects being decorated. As such, they're suitable for use in
any kind of Ruby program.

### Isn't a Decorator like a Presenter which is like an HTML macro?

In Blogylvania there is considerable disagreement about what these terms entail.
[In RefineryCMS, for example](http://refinerycms.com/guides/extending-controllers-and-models-with-decorators),
"decorating" a class means opening it up with a `class_eval`. (In this conception, the decorator isn't even
an _object_, which is astonishing in Ruby.)

I use the terms as follows: a "presenter" is an object which 
mediates between a model, controller, etc. and a view. A "decorator" is an object 
which answers messages ostensibly bound for another object, and either responds on its behalf or
lets it do whatever it was going to in the first place. 

### What's so special about these?

Decorum decorators are like GoF decorators, but they are designed to satisfy two more constraints,
_object identity_ and _implementation consistency._

#### Object Identity

In the GoF scheme, you aren't dealing with the same object after decoration. That's fine if
it's a totally anonymous interface, but if the identity of the object is significant---if
calling objects are storing references to them, say---it can become a problem. 
For example, in a common Rails idiom, if you want to do this:

```ruby
render @user
```

...having already `@user = User.find(params[:id])`, you'd better remember to do this:

```ruby
if latest_winners.include(@user.id)
  @user = FreeVacationCruiseDecorator.new(@user)
end
```
The controller has to update the reference for `@user` if it wants to decorate it.
The model's decoration status has essentially become part of the controller's state.

In Decorum, objects use decorator classes (descendents of Decorum::Decorator) to decorate themselves:

```ruby
if latest_winners.include?(@user.id)
  @user.decorate(FreeVacationCruiseDecorator, because: "You are teh awesome!")
  @user.assault_with_flashing_gifs! # # ==>= that method wasn't there before!
end
```

The "decorated object" is the same old object, because it manages all of its
state, including its decorations. References don't need to change, 
and state stays where it should.

#### Implementation Consistency

By design, Decorum decorators do not override the methods of the decorated object. In general, 
this seems like a bad practice. Obviously, there are edge cases, which is why this will probably
appear as an option at some point, but only with scolding. Consider: 

- It risks breaking interfaces across a class. Even if the decorator respects the 
method type, objects which are ostensibly identical (same database id, say) may differ
in their attributes. Suppose Bob's family calls him Skippy; with a NameDecorator, you could
have weird conditions like this:

```ruby
work.bob == home.bob
true
work.bob.name == home.bob.name
false
```

That may sound academic, but imagine what tracking this bug down might be like.

- More importantly: the fact that the method _needs_ overriding implies
the original object doesn't have the relevant state to fulfill it. This seems like evidence
the method belonged in the decorator to begin with. 

The delegation system in Decorum gives first preference to the original object. The decorator chain
is only consulted if the original object defers the request. GoF require that Decorators respect
the object's original interface; you could say Decorum requires that they respect the original
implementation as well.

### Tasteful Decorators
Decorators which satisfy the conditions stated earlier plus these two are "tasteful decorators," 
because they stay out of the way. (It's not a comment on other implementations. The name just
stuck.)

## Usage

### Helpers
The decorated object is accessible as either `#root` or `#object`. A helper method:

```ruby
class Royalty < Human
  # makes our model decoratable
  include Decorum::Decorations
  attr_accessor :fname, :lname, :array_of_middle_names, :array_of_styles
end

class StyledNameDecorator < Decorum::Decorator
  def styled_name
    parts = [:fname, :lname, :array_of_middle_names, :array_of_styles].map do |m|
      root.send(m)
    end.flatten

    ProperOrderOfStyles.sort_and_join_this_madness(parts)
  end
end

r = Royalty.find_by_palace_name(:bob)
r.respond_to? :styled_name # ==> false
r.decorate StyledNameDecorator
r.styled_name # ==> "Duke Baron His Grace Most Potent Sir Percy Arnold Robert \"Bob\" Gorpthwaite, Esq."
```

A decorator that keeps state: (code for these is in Examples)

```ruby
c = Coffee.new
# two milks
c.decorate(MilkDecorator, animal: "cow")
c.decorate(MilkDecorator, animal: "soycow")
# one sugar
c.decorate(SugarDecorator)
c.add_milk
c.add_sugar
c.milk_level  # # ==> 2
c.sugar_level # # ==> 1
```

Decorators are stackable, and can take an options hash. You
can declare decorator attributes in a few ways:

```ruby
class MilkDecorator < Decorum::Decorator
  attr_accessor :milk_type    
  share :milk_level
  default_attributes animal: "cow", milk_type: "two percent"
  ...
```

`attr_accessor` works like normal, in that it gets/sets state on the
decorator; when they are called on the decorated object, the most recent
decorator that implements the method will answer it. `share` declares an
attribute that is shared across all decorators of the same class on that
object; this shared state can be used for a number of purposes. Finally,
`default_attributes` lets you set class-level defaults; these will be
preempted by options passed to the constructor.

### Shared State

When attributes are declared with `share` (or `accumulator`), they
are shared among all decorators of that class on a given object:
if an object has three MilkDecorators, the `#milk_level`/`#milk_level=` methods
literally access the same state on all three.
In addition, you get `#milk_level?` and `#reset_milk_level` to
perform self-evident functions.

Access to the shared state is proxied first through the root object,
and then through an instance of Decorum::DecoratedState, before
ultimately pointing to an instance of Decorum::SuperHash. (SuperHash
is used for a few things---see the source. It's
normally OpenStruct, to limit Decorum's dependencies to the standard
library, but you can override it; I use Hashr personally.) 

In the examples above and below, shared state is mainly used to
accumulate results, like in `#milk_level`. It can also be used for 
other things:
- Serialize it, stick it in an HTML `data` attribute, and use it 
  to initailize Javascript applications
- Store a Rails view context for rendering

...or for more esoteric purposes:

- Provide context-specific response selections for decorators, e.g.,
  `return current_shared_responder.message(my_condition)` 
- Implement polymorphic factories as decorators by storing references to classes

And so on. 

### `#decorated_tail`

How exactly did the first MilkDecorator know to keep passing `#add_milk`
down the chain instead of returning, you ask? In general, the decision
whether to return directly or to pass the request down the chain for further
input rests with the decorator itself. Cumulative decorators, like the milk example,
can be implemented in Decorum with a form of tail recursion:

```ruby
class MilkDecorator < Decorum::Decorator
  share :milk_level
  ...
  def add_milk
    self.milk_level = milk_level.to_i + 1
    decorated_tail(milk_level) { next_link.add_milk }
  end
end
```

Because `milk_level` is shared across all of the instances of 
MilkDecorator attached to the current cup of coffee, each
decorator can update it individually. The "tail call" actually
goes down the decorator chain, and is picked up by the next 
decorator that implements the method. The call is wrapped
in `#decorated_tail`, which will catch the end of the decorator
chain, and return its argument; in this case, `#milk_level` called 
on the final instance, so, the total amount of milk in the coffee.
The state is saved, and because it's shared among all the MilkDecorators,
the most recent one on the chain can service the getter method
like a normal decorated attribute.

For a standard demonstration of tail recursion in Decorum, see
Decorum::Examples::FibonacciDecorator:

```ruby
fibber = SomeDecoratableClass.new
# generate the first 100 terms of the Fibonacci sequence
100.times do
  fibber.decorate(FibonacciDecorator)
end
# call it
fibber.fib  # ==> 927372692193078999176
# it stores both the return and the sequence in shared state:
fibber.sequence.length == 100  # ==> true
fibber.current  # ==> 927372692193078999176
```

`#decorated_tail` can be used to produce other results.
Normally, methods are handled by the most recent decorator in the chain
to implement it. To give the method to the _oldest_ decorator to
implement it, call `#decorated_tail` with a non-shared attribute/method:

```ruby
class MilkDecorator 
  attr_accessor :animal
  ...
  def first_animal
    decorated_tail(animal) { next_link.first_animal }
  end
end
```

This returns the animal responsible for the first MilkDecorator
Bob took. Or call it with some other object:

```ruby
  def all_animals(animals=[])
    animals << animal
    decorated_tail(animals) { next_link.all_animals(animals) }
  end
```

This will return a list of all of the animals who have contributed milk
to Bob's coffee.

If such a method returns normally, `#decorated_tail` will return that
value instead, enabling Chain of Responsibility-looking things like this:
(sorry, no code in the examples for this one)

```ruby
  [ErrorHandler, SuccessHandler].each do |handler|
    @agent.decorate(handler)
  end
  this_service = find_service_decorator(params) # # ==> SomeServiceHandler
  @agent.decorate(this_service)
  @agent.service_request(params)

  # meanwhile:

  class SomeServiceHandler < Decorum::Decorators
    def service_request
      status = perform_request_on(object)
      if status
        decorated_tail(DefaultSuccess.new) { next_link.special_success_method("Outstanding!") }
      else
        decorated_tail(DefaultFailure.new) { next_link.special_failure_method("uh-oh") }
      end
    end
  end  
```

You can now parameterize your responses based on whatever conditions you like,
by loading different decorators before the request is serviced. If nobody claims
the specialized method, your default will be returned instead.

### It's Decorators All the Way Down

Decorum includes a class called Decorum::BareParticular, which descends from
SuperHash. You can initialize any values you like on it, call them as methods,
and any method it doesn't understand will return nil. The only other distinguishing
feature of this class is that it can be decorated, so you can create objects
whose interfaces are defined entirely by their decorators, and which will
return nil by default.

## to-do
A few things I can imagine showing up soon:
- Namespaced decorators, probably showing up as a method on the root object,
  e.g., `object.my_namespace.namespaced_method`
- Thread safety: probably not an issue if you're retooling your Rails helpers,
  but consider a use case like this:

```ruby
  10.times do
    my_decorator = nil  # scope the name
    @object.decorate(RequestHandler) { |d| my_decorator = d }
    Thread.new do
      my_decorator.listen_for_changes_to_shared_state(...)
    end
  end
```

- Easy subclassing of Decorum::DecoratedState

&c. I'm open to suggestion.
 
## Contributing
I wrote most of this super late at night, so that would be awesome:

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
