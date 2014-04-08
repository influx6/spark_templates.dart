library engines;

import 'package:hub/hub.dart';

final _extraSpace = new RegExp(r'/s+');
final _key = new RegExp(r'#key');
final _value = new RegExp(r'#value');
final _loop = new RegExp(r'#index');
final _cursplit = new RegExp(r'{{|}}');
final _mutlipleNewLine = new RegExp(r'\n+');
final _selectionNotation = new RegExp(r'((::\w+)+)([\w\W\d\D]*)?');

abstract class TemplateEngine{
  dynamic tmpl;
  Function cloudator;

  TemplateEngine(this.tmpl,this.cloudator);

  void switchTmpl(dynamic n){
  	this.tmpl = n;
  }

  void render(dynamic val);

}

abstract class TemplateParser{
	dynamic parse(dynamic n);
}

class MetaTemplate extends TemplateEngine{

  static create(n) => new MetaTemplate(n);

  MetaTemplate(String n):super(n,(m){ 
    return ("#$m").toString().replaceAll(_extraSpace,''); 
  });

  void render(Map val){
    var mod = this.tmpl,handle = {};
    val.forEach((n,k){
      handle[new RegExp(this.cloudator(n))] = n;
    });

    handle.forEach((n,k){
    	if(!n.hasMatch(mod)) return;
        mod = mod.replaceAll(n,val[k].toString());
    });

    handle.clear();
    return mod;
  }

}

class EnumsTemplate extends TemplateEngine{
	RegExp key,value;

	static create(n,[k,v]) => new EnumsTemplate(n,k,v);

	EnumsTemplate(String m,[RegExp key,RegExp value]): super(m,null){
		this.key = Funcs.switchUnless(key,_key);
		this.value = Funcs.switchUnless(value,_value);
	}

	void render(dynamic val,[RegExp n,RegExp h]){
		var tmpl = [];

		var keyreg = Funcs.switchUnless(n,this.key);
		var valuereg = Funcs.switchUnless(h,this.value);

		if(val is List){
			var step = 0;
			val.forEach((n){
				step += 1;
				tmpl.add(this.tmpl.replaceAll(keyreg,step.toString()).replaceAll(valuereg,n.toString()));
			});
		}
		if(val is Map){
			val.forEach((k,v){
				tmpl.add(this.tmpl.replaceAll(keyreg,k.toString()).replaceAll(valuereg,v.toString()));
			});
		}
		return tmpl.join('\n');
	}
}

class LoopTemplate extends TemplateEngine{
	RegExp loop;

	static create(n,[l]) => new LoopTemplate(n,l);

	LoopTemplate(String m,[RegExp l]):super(m,null){
		this.loop = Funcs.switchUnless(l,_loop);
	}

	void render(int val,[RegExp p]){
		var looplist = [];
		var indreg  = Funcs.switchUnless(p,this.loop);

		Funcs.cycle(val,(index){
			// if(index == 0) return null;
			looplist.add(this.tmpl.toString().replaceAll(indreg,index.toString()));
		});

		return looplist.reversed.toList().join('\n');
	}

}

class MooseParser extends TemplateParser{
	static RegExp collectionMatcher = new RegExp(r'#collections{\s*(::\w+)((\s+)([\d\D\W\w+\d\D\W]*))}'); 
	static RegExp selectionMatcher = new RegExp(r'#selection{\s*(::\w+)((\s+)([\d\D\W\w+\d\D\W]*))}'); 
	static RegExp loopMatcher = new RegExp(r'#loop{\s*(::\w+)((\s+)(\d*\D*\W*\w+\d*\D*\W*))}');
	static RegExp markerMatcher = new RegExp(r'#\W*\w+\W*');
	static RegExp excessSpace = new RegExp(r'\s*');

	static create() => new MooseParser();

	MooseParser();

	void parse(String tmpl,List splits){
		var tokenList = [];

		splits.forEach((v){

			var hasCollection = MooseParser.collectionMatcher.hasMatch(v);
			var hasLoop = MooseParser.loopMatcher.hasMatch(v);
			var hasMarker = MooseParser.markerMatcher.hasMatch(v);
			var hasSelection = MooseParser.selectionMatcher.hasMatch(v);


			Funcs.when(hasCollection,(){
				var mark = MooseParser.collectionMatcher.firstMatch(v);
        var keyd = mark.group(1).replaceAll(MooseParser.excessSpace,'');
				tokenList.add({
					'signature': mark.group(0),
					'input': mark.input,
					'key': keyd,
					'type':'collections',
					'token': mark.group(2),
          'nsKey': keyd+"#key",
          'nsValue': keyd+"#value"
				});
			});

			Funcs.when(hasSelection,(){
				var mark = MooseParser.selectionMatcher.firstMatch(v);
        var keyd = mark.group(1).replaceAll(MooseParser.excessSpace,'');
				tokenList.add({
					'signature': mark.group(0),
					'input': mark.input,
					'key': keyd,
					'type':'selections',
					'token': mark.group(2),
          'nsKey': keyd+"#key",
          'nsValue': keyd+"#value"
				});
			});

			Funcs.when(hasLoop,(){
				var mark = MooseParser.loopMatcher.firstMatch(v);
        var keyd = mark.group(1).replaceAll(MooseParser.excessSpace,'');
				tokenList.add({
					'signature': mark.group(0),
					'input': mark.input,
					'key': keyd,
					'type':'loop',
					'token': mark.group(2),
          'nsKey':keyd+"#index",
				});
			});

			Funcs.when((!hasCollection && !hasLoop && !hasSelection && hasMarker),(){
				tokenList.add({
					'signature': v,
					'key': null,
					'type':'marker',
					'token': v,
					'input': v
				});
			});

			Funcs.when((!hasCollection && !hasLoop && !hasMarker && !hasSelection),(){
				tokenList.add({
					'signature': v,
					'key': null,
					'type':'text',
					'token': v,
					'input': v
				});
			});

		});

		return {
			'tokens': tokenList,
			'splits': splits
		};
	}
}


//flatt template engine
class MooseEngine extends TemplateEngine{
	final parser = MooseParser.create();
	final collections = EnumsTemplate.create("");
	final loops = LoopTemplate.create("");
	final metas = MetaTemplate.create("");
	RegExp splitter;

	static create(String n) => new MooseEngine(n);

	MooseEngine(String n,[RegExp s]): super(n,null){
		this.splitter = Funcs.switchUnless(s,_cursplit);
	}

	dynamic render(Map vals){
		var cache = this.parser.parse(this.tmpl,this.tmpl.split(this.splitter));
		return this.process(cache['tokens'],new List.from(cache['splits']),vals);
	}

	dynamic captureKey(String key,Map v){
		var item = v;
		key.split('::').forEach((j){
			if(j.isEmpty) return;
			if(item is List){
				var ind = int.parse(j);
				if(item.elementAt(ind) == null) return;
				item = item[ind];
			}
			if(item is Map){
				if(!item.containsKey(j)) return;
				item = item[j];
			}
		});

		return item;
	}

	List grabSelectionKeys(String m,[String cache]){
		var keyCache = Funcs.switchUnless(cache,[]);
		var match = _selectionNotation.firstMatch(m);

		keyCache.add(match.group(1));

		if(!_selectionNotation.hasMatch(match.group(3))) return keyCache;

		return this.grabSelectionKeys(match.group(3),keyCache);
	}

	void process(List cache,List mod,Map vals){
		var pick,res,repKey,repVal;

		cache.forEach((n){

			pick = Enums.nthFor(n);

			if(Valids.match(pick('type'),'text')) return;

			Funcs.when(Valids.match(pick('type'),'collections'),(){
				repKey = new RegExp(pick('key')+"#key");
				repVal = new RegExp(pick('key')+"#value");

				var item = this.captureKey(pick('key'),vals);

				this.collections.switchTmpl(pick('token'));
				var res = this.collections.render(item,
					(repKey.hasMatch(pick('token')) ? repKey : null),
					(repVal.hasMatch(pick('token')) || repKey.hasMatch(pick('token')) ? repVal : null));


				var ind = mod.indexOf(pick('input'));
				mod[ind] = mod[ind].replaceAll(pick("signature"),res);
			});

			Funcs.when(Valids.match(pick('type'),'selections'),(){

				var token = pick('token');
				var keys = this.grabSelectionKeys(token);
				var targets = Enums.map(keys,(e,i,o){
					return _selectionNotation.firstMatch(e).group(2);
				});

				var item = this.captureKey(pick('key'),vals);

				keys.forEach((n){
					var tag = targets.elementAt(keys.indexOf(n));
					var val = this.captureKey(tag,item);

					token = token.replaceAll(n,val);
				});

				var ind = mod.indexOf(pick('input'));
				if(ind == -1) return;
				mod[ind] = mod[ind].replaceAll(pick("signature"),token);
			});

			Funcs.when(Valids.match(pick('type'),'loop'),(){
				repKey = new RegExp(pick('key')+"#index");

				var item = this.captureKey(pick('key'),vals);

				this.loops.switchTmpl(pick('token'));
				var res = this.loops.render(item,(repKey.hasMatch(pick('token')) ? repKey : null));
				var ind = mod.indexOf(pick('input'));
				mod[ind] = mod[ind].replaceAll(pick('signature'),res);
			});

			Funcs.when(Valids.match(pick('type'),'marker'),(){
				this.metas.switchTmpl(pick('token'));
				res = this.metas.render(vals);
				mod[mod.indexOf(pick('signature'))] = res;
			});

		});
		
		var parsed = mod.join('\n');

		if(!MooseParser.collectionMatcher.hasMatch(parsed) && 
			!MooseParser.loopMatcher.hasMatch(parsed)) return parsed.replaceAll(_mutlipleNewLine,'\n');

		var split = parsed.split('\n');
		var partialParsed = this.parser.parse(parsed,split);
		return this.process(partialParsed['tokens'],split,vals);

	}

}
