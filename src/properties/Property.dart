class Property<T> implements Hashable{
  static final Object Undefined = const _UndefinedValue();
  static int _globalId = 0;

  final int _id;
  final String name;
  final T defaultValue;
  final Func<T> _factory;

  const Property(String this.name, [T this.defaultValue = null]) :
    _id = _globalId++,
    _factory = null;

  // TODO: must test factory methods, yo
  const Property.withFactory(String this.name, Func<T> this._factory) :
    _id = _globalId++,
    defaultValue = null;

  T get(IPropertyObject obj){
    var coreValue = getCore(obj);
    if(coreValue != Undefined){
      return coreValue;
    }
    else{
      return defaultValue;
    }
  }

  Object getCore(IPropertyObject obj){
    return obj.propertyValues._getValueOrUndefined(this, _factory);
  }

  void set(IPropertyObject obj, T value){
    assert(value != Undefined);
    obj.propertyValues._set(this, value);
    _PropertyChangeHelper.fireHandlers(obj, this);
  }

  void clear(IPropertyObject obj){
    obj.propertyValues._remove(this);
    _PropertyChangeHelper.fireHandlers(obj, this);
  }

  bool isSet(IPropertyObject obj){
    return obj.propertyValues._isSet(this);
  }

  void addHandler(IPropertyObject obj, PropertyChangedHandler handler){
    _PropertyChangeHelper.addHandler(obj, this, handler);
  }
  
  void removeHandler(IPropertyObject obj, PropertyChangedHandler handler){
    _PropertyChangeHelper.removeHandler(obj, this, handler);
  }  

  int hashCode(){
    return _id;
  }
}

typedef void PropertyChangedHandler(IPropertyObject obj, Property property);

class _UndefinedValue{
  const _UndefinedValue();
  // TODO: toString?
}

class _PropertyChangeHelper{
  // TODO: once we can define static final with 'new' instead of 'const', we can nuke the property redirection
  static Property<_PropertyChangeHelper> __changeHelperProperty;

  final HashMap<Property, _SimpleSet<PropertyChangedHandler>> _handlers;

  _PropertyChangeHelper() : _handlers = new HashMap<Property, _SimpleSet<PropertyChangedHandler>>();


  static Property<_PropertyChangeHelper> get _changeHelperProperty(){
    if(__changeHelperProperty == null){
      __changeHelperProperty = new Property<_PropertyChangeHelper>.withFactory("_changeHelperProperty", createInstance);
    }
    return __changeHelperProperty;
  }

  static _PropertyChangeHelper createInstance(){
    return new _PropertyChangeHelper();
  }

  static void addHandler(IPropertyObject obj, Property property, PropertyChangedHandler watcher){
    var helper = _changeHelperProperty.get(obj);
    helper.getSet(property).add(watcher);
  }

  static void removeHandler(IPropertyObject obj, Property property, PropertyChangedHandler watcher){
    var helper = _changeHelperProperty.get(obj);
    helper.getSet(property).remove(watcher);
  }

  static void fireHandlers(IPropertyObject obj, Property property){
    var helper = _changeHelperProperty.get(obj);
    var theSet = helper.getSet(property);
    theSet.forEach((h){
      h(obj, property);
    });
  }

  _SimpleSet<PropertyChangedHandler> getSet(Property property){
    return _handlers.putIfAbsent(property, propSetCreator);
  }

  static _SimpleSet<PropertyChangedHandler> propSetCreator(){
    return new _SimpleSet<PropertyChangedHandler>();
  }
}

class _SimpleSet<T>{
  final List<T> _items;

  _SimpleSet():_items = new List<T>();

  // NOTE: this is not 100% set-ish. 'add' should just ignore duplicates, not assert
  void add(T item){
    assert(_items.indexOf(item) == -1);
    _items.add(item);
  }
  
  bool remove(T item){
    var index = _items.indexOf(item);
    if(index >= 0){
      _items.removeRange(index, 1);
      return true;
    }
    return false;
  }

  void forEach(void f(T element)){
    _items.forEach(f);
  }
}