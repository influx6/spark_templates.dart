library spark.elements;

import 'package:sparkflow/sparkflow.dart';
import 'package:spark_templates/engines.dart' as engine;
import 'package:hub/hub.dart';

export 'package:sparkflow/sparkflow.dart';

class Templates{
    static void registerComponents(){

        Component.registerComponents();

        SparkRegistry.addMutation('templates/template',(shell){

           shell.createSpace('in');
           shell.createSpace('out');

           shell.makeInport('in:tmpl');
           shell.makeInport('in:data');
           shell.makeOutport('out:res');

           shell.port('static:option').bindPort(shell.port('in:tmpl'));
          
        });

        SparkRegistry.addBaseMutation('templates/template','templates/looptemplate',(shell){

            var looper = engine.LoopTemplate.create("");

            shell.makeInport('in:regexp');

            shell.port('in:regexp').tap((p){
              var n = p.data;
              looper.loop = (n is RegExp ?  n : (n is String ? new RegExp(n) : null));
            });
          
            shell.port('in:tmpl').tap((n){
              if(n.data is! String) return null;
              looper.switchTmpl(n.data);
            });
            
            shell.port('in:data').forceCondition((n){
               return (Valids.isMap(n) || n is int);
            });

            shell.port('in:data').tap((n){
              var m = (n.data is Map ? n.data['count'] : n.data);
              shell.port('out:res').send(looper.render(m));
            });


        });

        SparkRegistry.addBaseMutation('templates/template','templates/collectiontemplate',(shell){

          var collects = engine.EnumsTemplate.create("");
          shell.makeInport('in:key');
          shell.makeInport('in:value');
          shell.makeInport('in:kvlist');
        
          shell.port('in:key').tap((n){
            collects.key = (n.data is RegExp ?  n.data : (n.data is String ? new RegExp(n.data) : null));
          });

          shell.port('in:value').tap((n){
            collects.value = (n.data is RegExp ?  n.data : (n.data is String ? new RegExp(n.data) : null));
          });

          shell.port('in:kvlist').tap((n){
            if(n.data is! List) return null;
            shell.port('in:key').send(Enums.first(n.data));
            shell.port('in:value').send(Enums.second(n.data));
          });

          shell.port('in:tmpl').tap((n){
            if(n.data is! String) return null;
            collects.switchTmpl(n.data);
          });

          shell.port('in:data').tap((n){
            if(n.data is Map || n.data is List)
              return shell.port('out:res').send(collects.render(n.data));
          });

        });

        SparkRegistry.addBaseMutation('templates/template','templates/stringtemplate',(shell){

            var matcher,tmpl;
            shell.makeInport('in:regexp');

            shell.port('in:regexp').tap((n){
              matcher = (n.data is RegExp ?  n.data : (n.data is String ? new RegExp(n.data) : null));
            });

            shell.port('in:tmpl').tap((n){
              if(n.data is! String) return;
              tmpl = n.data.toString().replaceAll('////n','/n');
            });

            shell.port('in:data').tap((n){
              if(Valids.notExist(matcher) || Valids.notExist(tmpl)) return;
              shell.port('out:res').send(tmpl.replaceAll(matcher,n.data));
            });
        });

        SparkRegistry.addBaseMutation('templates/template','templates/MetaTemplate',(shell){
            
              var templator = engine.MetaTemplate.create("");
              shell.makeInport('in:keyfier');

              shell.port('in:keyfier').tap((n){
                if(n.data is! Function) return null;
                templator.cloudator = n.data;
              });

              shell.port('in:tmpl').tap((n){
                if(n.data is! String) return null;
                templator.switchTmpl(n.data);
              });

              shell.port('in:data').tap((n){
                if(n.data is! Map) return null;
                shell.port('out:res').send(templator.render(n.data));
              });

        });
    }
}

