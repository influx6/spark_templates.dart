library spark.elements;

import 'package:sparkflow/sparkflow.dart';
import 'package:spark_templates/engines.dart' as engine;
import 'package:hub/hub.dart';

export 'package:sparkflow/sparkflow.dart';

class Templates{
    static void registerComponents(){
        Component.registerComponents();
        SparkRegistry.register('templates','template',Template.create);
        SparkRegistry.register('templates','StringTemplate',StringTemplate.create);
        SparkRegistry.register('templates','CollectionTemplate',CollectionTemplate.create);
        SparkRegistry.register('templates','MetaTemplate',MetaTemplate.create);
        SparkRegistry.register('templates','LoopTemplate',LoopTemplate.create);
    }
}

class Template extends Component{

  static create() => new Template();

  Template([String id]): super(Hub.switchUnless(id,'Template')){

     this.removeDefaultPorts();

     this.makePort('in:tmpl');
     this.makePort('in:data');
     this.makePort('out:res');

     this.port('static:option').bindPort(this.port('in:tmpl'));

  }

}

class MetaTemplate extends Template{
  final templator = engine.MetaTemplate.create("");

  static create() => new MetaTemplate();

  MetaTemplate(): super("MetaTemplate"){
    
      this.makePort('in:keyfier');

      this.port('in:keyfier').tap((n){
        if(n.data is! Function) return null;
        this.templator.cloudator = n.data;
      });

      this.port('in:tmpl').tap((n){
        if(n.data is! String) return null;
        this.templator.switchTmpl(n.data);
      });

      this.port('in:data').tap((n){
        if(n.data is! Map) return null;
        this.port('out:res').send(this.templator.render(n.data));
      });
  }

}

class LoopTemplate extends Template{
  final looper = engine.LoopTemplate.create("");

  static create() => new LoopTemplate();

  LoopTemplate(): super('LoopTemplate'){
    
    this.makePort('in:regexp');

    this.port('in:regexp').tap((p){
      var n = p.data;
      this.looper.loop = (n is RegExp ?  n : (n is String ? new RegExp(n) : null));
    });
  
    this.port('in:tmpl').tap((n){
      if(n.data is! String) return null;
      this.looper.switchTmpl(n.data);
    });

    this.port('in:data').tap((n){
      if(n.data is! int) return null;
      this.port('out:res').send(this.looper.render(n.data));
    });

  }
}

class CollectionTemplate extends Template{
  final collects = engine.EnumsTemplate.create("");

  static create() => new CollectionTemplate();

  CollectionTemplate(): super('CollectionTemplate'){
    
    this.makePort('in:key');
    this.makePort('in:value');
    this.makePort('in:kvlist');
  
    this.port('in:key').tap((n){
      this.collects.key = (n.data is RegExp ?  n.data : (n.data is String ? new RegExp(n.data) : null));
    });

    this.port('in:value').tap((n){
      this.collects.value = (n.data is RegExp ?  n.data : (n.data is String ? new RegExp(n.data) : null));
    });

    this.port('in:kvlist').tap((n){
      if(n.data is! List) return null;
      this.port('keyreg').send(Enums.first(n.data));
      this.port('valuereg').send(Enums.second(n.data));
    });

    this.port('in:tmpl').tap((n){
      if(n.data is! String) return null;
      this.collects.switchTmpl(n.data);
    });

    this.port('in:data').tap((n){
      if(n.data is Map || n.data is List)
        return this.port('out:res').send(this.collects.render(n.data));
    });

  }

}

class StringTemplate extends Template{
  var matcher,tmpl;

  static create() => new StringTemplate();

  StringTemplate(): super('StringTemplate'){

    this.makePort('in:regexp');

    this.port('in:regexp').tap((n){
      this.matcher = (n.data is RegExp ?  n.data : (n.data is String ? new RegExp(n.data) : null));
    });

    this.port('in:tmpl').tap((n){
      if(n.data is! String) return;
      this.tmpl = n.data.toString().replaceAll('////n','/n');
    });

    this.port('in:data').tap((n){
      if(Valids.notExist(matcher) || Valids.notExist(tmpl)) return;
      this.port('out:res').send(this.tmpl.replaceAll(this.matcher,n.data));
    });
  }
}



