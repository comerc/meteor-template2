Package.describe({
  summary: 'Syntactic sugar for blaze templates',
  name: 'comerc:template2',
  version: '1.0.0',
  git: 'https://github.com/comerc/meteor-template2.git'
});

Package.onUse(function(api) {

  // Have to stay on Meteor 1.2.1 to be compatible with all Meteor versions.
  api.versionsFrom('1.2.1');

  api.use([
    'coffeescript',
    'ecmascript',
    'reactive-var',
    'templating',
    'blaze-html-templates',
    'comerc:template-two-way-binding@1.4.0'
  ]);

  api.addFiles([
    'src/model-map.coffee',
    'src/template2.js'
  ], 'client');

});
