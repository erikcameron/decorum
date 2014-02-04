# Decorum
[![Gem Version](https://badge.fury.io/rb/decorum.png)](http://badge.fury.io/rb/decorum)
[![Build Status](https://travis-ci.org/erikcameron/decorum.png?branch=master)](https://travis-ci.org/erikcameron/decorum)

Decorum implements lightweight decorators
for Ruby, called "tasteful decorators." (See below.)  It is very small,
possibly very fast, and has no requirements outside of the standard
library.  Use it wherever.

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

## New in 0.3.0
- Methods may be called directly on decorators
- Decorator namespaces
- Set superhash and shared state classes via environment
- Entire decorator interfaces may be declared `immediate` (see below)
- #post_decorate callback

## About

[Skip to the action](#usage)

Decorum expands on the traditional Decorator concept by satisfying [a few additional 
contraints](#tasteful-decorators). The constraints are designed to make decorators' role in your 
overall object structure both clear and safe. More on these points below.

- Object Identity: After you decorate an object, you're still dealing with that same
object. 
- Defers to the original interface: by default, Decorum decorators will _not_ override
the decorated object's public methods. (Though you can instruct it to.) This is intentional.
- Respects existing overrides of `#method_missing`
- Decorators are unloadable

By adhering to these constraints, decorators tend to do the Right Thing, i.e, integrate into existing
applications easily, and stay out of the way when they aren't doing your bidding. Hence "[tasteful
decorators](#tasteful-decorators)." (Not meant to imply others are tacky. The name just stuck.)

In addition, Decorum provides a few helpful features:

- Stackable decorators, with shared state 
- Recursion, via `#decorated_tail`
- Intercept/change/reroute messages, a la Chain of Reponsibility
- Build stuff entirely out of decorators

As an example of how this is in use right now, suppose you're interfacing a content
management system with an existing data application. You want to build a sidebar 
of image links. The images are in the CMS, but their metadata are stored in the application.
You want those systems to stay uncoupled. You can use a decorator to slap the metadata 
on the image at runtime, e.g.,:

```ruby
image_collection = Application::ImageData.sidebar_images
images = Cms::Images.where(identifier: image_collection.keys)
# ==> { blah: { url: 'http://blah.foo/', alt: 'The Blah Conglomerate' ... }}

images.each do |img|
  img.decorate(ImageMetaDecorator, image_collection[img.identifier])
end

# defined in ImageMetaDecorator:
images[0].url # ==> 'http://blah.foo'
images[0].alt # ==> 'The Blah Conglomerate'
images[0].fetch_thumbnail_or_queue_to_create
```

### Isn't a Decorator like a Presenter which is like an HTML macro?

In Blogylvania there is some disagreement
about what these terms entail.  [For example, in
RefineryCMS](http://refinerycms.com/guides/extending-controllers-and-models-with-decorators),
"decorating" a class means opening it up with a `class_eval`. (In this
conception, the decorator isn't even an object, which is astonishing
in Ruby.) I use the terms as follows: a "presenter" is an object which
mediates between a model, controller, etc. and a view. A "decorator" is
an object which answers messages ostensibly bound for another object, and
either responds on its behalf or lets it do whatever it was going to in
the first place. Presenters may or may not be implemented as Decorators;
Decorators may or may not present.

Like "traditional" (i.e., [Gang of Four](http://en.wikipedia.org/wiki/Design_Patterns)-style)
decorator patterns, Decorum is a general purpose, object-oriented tool. Use it wherever.

### Tasteful Decorators

#### Object Identity

Decorators, as conceived of by GoF, Python, etc., masquerade as the
objects they decorate by responding to their interface. They are _not_ the
original objects themselves. This may or may not be a problem, depending
on how your code is structured. In general though, (I doubt this is news)
it risks breaking encapsulation: Any code which stores direct references
to the original object will have to update them to get the decorated
behavior.  For example, in a common Rails idiom, in order to do this:

```ruby
render @user
```

...having already `@user = User.find(params[:id])`, you have to do this:

```ruby
if latest_winners.include(@user.id)
  @user = FreeVacationCruiseDecorator.new(@user)
end
```

`@user` is an instance variable of the controller, but it has to be
updated in order for the model to be decorated.  In practical terms,
if you store multiple references to the same object, (say the
original object is in an array somewhere, in addition to `@user`) 
you have to update both references to get consistent behavior. The model's
decoration status has essentially become part of the controller's state.

```ruby
users.include?(@user) # ==> true
winning_users = users.map { |u| FreeVacationCruiseDecorator.new(u) }
decorated = winning_users.detect { |u| u.id == @user.id } # the decorated object---should be the "same" thing
decorated.destination # ==> "tahiti"
@user.destination # ==> NoMethodError
```
In Decorum, objects use decorator classes (descendents of Decorum::Decorator) to decorate themselves:

```ruby
users.each do |user|
  user.decorate(FreeVacationCruiseDecorator, because: "You are teh awesome!")
end

@user.assault_with_flashing_gifs! # ==> that method wasn't there before!
```

The "decorated object" is the same old object, because it manages all of its
state, including its decorations. References don't need to change, 
and state stays where it should.

#### Defers to the original interface

Unless instructed otherwise, Decorum will not override existing methods
on the decorated object. (See below for how to instruct it otherwise.)
There are certainly cases where this is useful, and having come across
one myself since the 0.2.0 release, I've amended my position slightly. But
not much.

I'm suspicious of this practice, as it blurs the line between
"decorating" an object and straight-up monkey patching it.  The fact that the method
_needs_ overriding implies the original object doesn't have the relevant
state to fulfill it. The method is now spread out over two classes,
that of the original object and that of the decorator. This may be
unavoidable, or monkey patching may be your intention---in that case,
by all means. But I don't think it's a pattern to be designed to.

The paradigm cases of decorators don't generally address overriding either. Consider three
common examples:

- Adding a scrollbar to a window
- Adding milk to a cup of coffee
- Providing `#full_name` to an object that supplies `#first_name` and `#last_name`

In all of these cases, the decorators provide some new functionality;
they don't change the object's original implementation. Obviously, you
shouldn't rule it out just because the common examples don't have it,
but it's by no means an essential use of the pattern. And from a design
perspective, it's a red flag that concerns are becoming... unseparated.
(It also risks weird bugs by breaking transparency, i.e., you can have
cases where `a` and `b` are literally identical, but have different 
attributes.) With Decorum, you can implement that entire domain of behavior,
possibly using a [namespace](#namespaced-decorators).

When an object is decorated, Decorum inserts its own `#method_missing`
and `#respond_to_missing?` into the object's eigenclass. Decorum's `#method_missing`
is only consulted after the original object has abandoned the message. (When
overriding original methods with `immediate`, each method gets its own 
redirect in the eigenclass as well, intercepting the message before the
original definition is found.)

#### Respects existing overrides of `#method_missing`

A sizeable amount of the world's total Ruby functionality is implemented
by overriding `#method_missing`, so decorators shouldn't get in the way.
Because Decorum intercepts messages in the objects eigenclass, it also
respects existing class-level overrides. If the decorator chain doesn't claim the
message, `super` is called and lookup proceeds normally.

#### Unloadable decorators

Decorators can be unloaded, if necessary:

```ruby
@bob.decorate(IsTheMole)
@bob.revoke_security_clearances 

class IsTheMole < Decorum::Decorators
  # callback
  def post_decorate
    object.revoke_security_clearances
  end

  def revoke_security_clearances
    clearances = object.decorators.select { |d| d.is_a?(SecurityClearance) }
    clearances.each { |clearance| object.undecorate(clearance) }
  end
end
```

### Implementation

As in other implementations, Decorum decorators wrap another object
to which they forward unknown messages.  In both cases, all decorators
other than the first wrap another decorator.  Instead of wrapping the
original object however, the first decorator in Decorum wraps an instance
of Decorum::ChainStop. If a method reaches the bottom of the chain, this
object throws a signal back up the stack to Decorum's `#method_missing`,
which then calls `super.` (This is a throw/catch, not an exception,
which would be significantly slower.)

See the source for more details.

## Usage

First, objects need to be decoratable. You can do this for a whole class,
by including Decorum::Decorations, or for a single object, by extending it.
(Note: this alone doesn't change the object's method lookup. It just makes
`#decorate` available on the object. The behavior is only changed when
`#decorate` is called.) The easiest way is probably including 
Decorum::Decorations at whatever point(s) of the class hierarchy you
feel appropriate.

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
    ProperOrderOfStyles.sort_and_join_this_madness(object)
  end
end

r = Royalty.find_by_palace_name(:bob)
r.respond_to? :styled_name # ==> false
r.decorate StyledNameDecorator
r.styled_name # ==> "His Grace Most Potent Baron Sir Percy Arnold Robert \"Bob\" Gorpthwaite, Esq."
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

As a side note, you can disable another decorators methods thus:

```ruby
class MethodDisabler < Decorum::Decorator
  def method_to_be_disabled(*args)
    throw :chain_stop, Decorum::ChainStop.new
  end
end
```

### Shared State

When attributes are declared with `share` (or `accumulator`), they
are shared among all decorators of that class on a given object:
if an object has three MilkDecorators, the `#milk_level`/`#milk_level=` methods
literally access the same state on all three.
In addition, you get `#milk_level?` and `#reset_milk_level` to
perform self-evident functions.

Access to the shared state is proxied first through the root object,
and then through an instance of Decorum::DecoratedState, before
ultimately pointing to an instance of Decorum::SharedState. This
class can be set via the environment (see lib/decorum.rb).

In the examples above and below, shared state is mainly used to
accumulate results, like in `#milk_level`. It can also be used for 
other things:
- Serialize it, stick it in an HTML `data` attribute, and use it 
  to initailize Javascript applications
- Store a Rails view context for rendering
- Provide context-specific response selections for decorators, e.g.,
  `return current_shared_responder.message(my_condition)` 

And so on. 

### `#decorated_tail`

How exactly did the first MilkDecorator pass `#add_milk`
down the chain instead of returning? In general, the decision
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

For a demonstration of tail recursion in Decorum, see
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
  handlers = condition ? [ErrorA, SuccessA] : [ErrorB, SuccessB]
  handlers.each do |handler|
    @agent.decorate(handler)
  end
  this_service = determine_service_decorator(params) # # ==> SomeServiceHandler
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

### Calling decorators directly

An object's decorators are available via `#decorators`, or by passing a block to `#decorate`:

```ruby
@object.decorate(SomeDecorator) { |dec| @this_decorator = dec }
@object.decorators # <== array of decorators

# start a request in the middle of the decorator chain:
@the_decorator_im_looking_for = @object.decorators.detect { |d| d.name == "cool decorator, bro" }
@the_decorator_im_looking_for.some_method
```

(Note that these methods pass the decorator(s) back wrapped in Decorum::CallableDecorator, 
which is necessary to call methods on them directly.)

### Namespaced Decorators

As noted above, overriding an objects public methods breaks behavior over two 
different classes. To package a domain of behavior in a namespace using Decorum:

```ruby
@request.decorate(MyRouter, namespace: "routes")
@request.routes.my_route(path: "foo/bar")
# namespaces pass anything they can't do back to the root
# object, so they effectively override it:
@request.routes.defined_on_request_object? # <== true
```

This way, you don't have to define a `#my_route` stub on the original class for
undecorated instances, and the public method of the original object is available
on (and in) the namespace.

### Overriding existing methods

To give decorator methods preference over an objects existing methods (if you
must) declare the method `immediate`:

```ruby
class StrongWilledDecorator < Decorum::Decorator
  immediate :method_in_question

  def method_in_question
    "overridden"
  end
end

x = WeakWilledClass.new
x.method_in_question # <== "original"
x.decorate(StrongWilledDecorator)
x.method_in_question # <== "overridden"
```

If you declare `immediate` with no arguments, the decorators entire public interface
is used. 

### Decorators All the Way Down

Decorum includes a class called Decorum::BareParticular, which descends from
SuperHash. You can initialize any values you like on it, call them as methods,
and any method it doesn't understand will return nil. The only other distinguishing
feature of this class is that it can be decorated, so you can create objects
whose interfaces are defined entirely by their decorators, and which will
return nil by default.

## To-do
A few things I can imagine showing up soon:
- An easy way to alias the main methods (#decorate, #undecorate), as you might
  want those names for something else.
- Thread safety: probably not an issue if you're retooling your Rails helpers,
  but consider a case like this:

```ruby
  10.times do |i|
    port = port_base + i  # 3001, 3002, 3003...
    @server.decorate(RequestHandler, port: port ) 
    Thread.new do
      @server.listen_for_changes_to_shared_state(port: port)
    end
  end
```

&c. I'm open to suggestion.
 
## Contributing
I wrote most of this super late at night, (don't worry, the tests pass!) so that would be awesome:

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
