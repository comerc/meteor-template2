Package.describe({
  summary: 'Syntactic sugar for blaze templates',
  name: 'comerc:template2',
  version: '1.4.3',
  git: 'https://github.com/comerc/meteor-template2.git'
});

Package.onUse(function(api) {

  // Have to stay on Meteor 1.2.1 to be compatible with all Meteor versions.
  api.versionsFrom('1.2.1');

  api.use([
    'coffeescript',
    'underscore',
    'ecmascript',
    'reactive-var',
    'templating',
    'blaze-html-templates',
    'comerc:template-two-way-binding@1.6.0'
  ], 'client');

  api.addFiles([
    'src/_export.coffee',
    'src/reactive-object.js',
    'src/template2.coffee',
    'src/model-map.coffee'
  ], 'client');

  api.export('Template2', 'client');
});
