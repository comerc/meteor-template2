Package.describe({
  summary: 'Syntactic sugar for blaze templates',
  name: 'comerc:template2',
  version: '0.0.1',
  git: 'https://github.com/comerc/meteor-template2.git'
});

Package.onUse(function(api) {

  // Have to stay on Meteor 1.2.1 to be compatible with all Meteor versions.
  api.versionsFrom('1.2.1');

  api.use([
    'ecmascript',
    'reactive-var',
    'templating',
    'blaze-html-templates'
  ]);

  api.addFiles([
    'template2.js'
  ], 'client');

});
