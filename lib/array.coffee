# Establish the object that gets returned to break out of a loop iteration.
# Safely convert anything iterable into a real, live array.
Array.toArray = (iterable) ->
  return [] if (!iterable)                
  return iterable.toArray() if (iterable.toArray)         
  return slice.call(iterable) if (_.isArray(iterable))      
  return slice.call(iterable) if (_.isArguments(iterable))  
  return _.values(iterable)

Tagen.mixin Array, Enumerable

Tagen.reopen Array,
  # each() => <#Enumerator>
  # each(iterator) => 
  #
  # support break by `throw BREAKER`
  #
  # callback(value, index, self)
  each: (iterator) ->
    return new Enumerator(this) unless iterator

    try
      for v, i in this
        iterator(v, i, this)
    catch err
      throw err if err != BREAKER

  isEqual: (ary) ->
    return false if @length != ary.length
    for v, i in this
      if v.instanceOf(Array) 
        return v.isEqual(ary[i]) 
      else
        return false if v != ary[i]
    return true

  # alias contains
  isInclude: (obj) ->
    @indexOf(obj) != -1

  isEmpty: ->
    @length == 0

  # shadow-clone
  clone: ()->
    @slice()

  random: ->
    i = Math.random() * @length
    this[Math.floor(i)]

  # Zip together multiple lists into a single array -- elements that share
  # an index go together.
  zip: (args...) ->
    args = [ this, args...]
    length = args.pluck('length').max()
    ret = new Array(length)
    for i in [0...length]
      ret[i] = args.pluck("#{i}")
    return ret

  # Get the first element of an array. Passing **n** will return the first N
  # values in the array
  #
  # first() => value
  # first(n) => Array
  first: (n) ->
    if n then @slice(0, n) else this[0]

  # Get the last element of an array. Passing **n** will return the last N
  # values in the array
  #
  # last() => value
  # last(n) => Array
  last: (n)  ->
    if n then @slice(@length-n) else this[@length-1]

  # Trim out all null values from an array.
  compact: () ->
    @findAll (value) -> 
      value != null

  # Return a completely flattened version of an array.
  #
  # flatten(shallow=false)
  flatten: (shallow) -> 
    ret = []
    @each (v) ->
      if v.instanceOf(Array)
        v = if shallow then v else v.flatten()
        ret = ret.concat v
      else
        ret.push v

    ret

  # Produce a duplicate-free version of the array. If the array has already
  # been sorted, you have the option of using a faster algorithm.
  #
  # uniq(isSorted=false)
  uniq: (isSorted) ->
    ret = []

    @each (v, i) ->
      if 0 == i || (if isSorted == true then ret.last() != v else !ret.isInclude(v)) 
        ret.push v
      ret

    return ret

  # Return a version of the array that does not contain the specified value(s).
  without: (args...) ->
    @findAll (value) -> !args.isInclude(value)

  # data like [ {a: 1}, {a: 2} .. ]
  #
  pluck: (key) ->
    @map (data) ->
      data[key]

  # findIndex(value)
  # findIndex(fn[v]=>bool)
  #
  # => -1
  findIndex: (obj) ->
    switch obj.constructorName()
      when 'Function'
        iterator = obj
      else
        iterator = (v)->
          v == obj

    ret = -1
    @each (v, i, self)->
      if iterator(v, i, self)
        ret = i
        throw BREAKER

    ret

  # Invoke a method (with arguments) on every item in a collection.
  # => null if no method
  invoke: (methodName, args...) ->
    @map (value) ->
      method = value[methodName]
      if method 
        method.apply(value, args...)
      else
        null

# alias
Array::contains = Array::isInclude

# If the browser doesn't supply us with indexOf (I'm looking at you, **MSIE**),
# we need this function. Return the position of the first occurrence of an
# item in an array, or -1 if the item is not included in the array.
# Delegates to **ECMAScript 5**'s native `indexOf` if available.
# If the array is large and already in sort order, pass `true`
# for **isSorted** to use binary search.
unless Array::indexOf
  Array::indexOf = (item, isSorted) ->
    return -1 if (this == null) 

    if isSorted
      i = _.sortedIndex(this, item)
      return if this[i] == item then i else -1

    for k, i in this
      return i if (k == item)
    return -1

# Delegates to **ECMAScript 5**'s native `lastIndexOf` if available.
unless Array::lastIndexOf
  Array::lastIndexOf = (item) ->
    return -1 if (this == null) 
    i = @length
    while (i--) 
      return i if (this[i] == item) 
    return -1
