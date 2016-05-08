ReactiveObject = class ReactiveObject {
  constructor(properties = {}) {
    this.addProperties(properties);
  }
  addProperty(key, defaultValue = null) {
    const property = new ReactiveVar(defaultValue);
    Object.defineProperty(this, key, {
      get: () => { return property.get(); },
      set: (value) => { property.set(value); }
    });
  }
  addProperties(properties = {}) {
    for (let key of Object.keys(properties)) {
      this.addProperty(key, properties[key]);
    }
  }
}
