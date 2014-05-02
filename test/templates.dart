library specs;

import 'package:spark_templates/templates.dart';

void main(){

  Templates.registerComponents();

  var stringer = SparkRegistry.generate('templates/StringTemplate');

  stringer.port('static:option').send('i love #name!');
  stringer.port('in:regexp').send('#name');
  stringer.port('out:res').tap(print);
  stringer.port('in:data').send('evelyn');

  var meta = SparkRegistry.generate('templates/metatemplate');
  meta.port('out:res').tap(print);
  meta.port('in:tmpl').send('socratic #name are #state');
  meta.port('in:data').send({'name':'scolars','state':'dead'});
  
  var loop = SparkRegistry.generate('templates/looptemplate');
  loop.port('out:res').tap(print);
  loop.port('in:tmpl').send('#index day of love');
  loop.port('in:data').send(6);
  loop.port('in:data').send({'count':2});

  var collect = SparkRegistry.generate('templates/collectiontemplate');
  collect.port('out:res').tap(print);
  collect.port('in:tmpl').send('#key day of love #value');
  collect.port('in:data').send({'state':'blue','country':'books'});

}
