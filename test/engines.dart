library spark.elements.spec;

import 'package:spark_templates/engines.dart';

void main(){

	var sim = MetaTemplate.create("My name is #name who went to #school");
	assert(sim.render({'school':'lcp','name':"alex"}) is String);

	var enumd = EnumsTemplate.create("<account id='#key'>#value</account>");
	assert(enumd.render(['sugar','rice','plantain']).split('\n').length == 3);
	assert(enumd.render({'1':'sugar','2':'rice','4':'chicken'}).split('\n').length == 3);

	var loop = LoopTemplate.create('sugar #index');
	assert(loop.render(5).split('\n').length == 6);

	var moose = MooseEngine.create("""{{<article>}}
		{{ <h3>My PromoCard </h3> }}
		{{<card> name: #name </card>}}
		{{#collections{::details <info id='::details#key'> ::details#value </info>} }} 
		{{ <section> 
			#loop{::entry <article>::entry#index sheep</article> }
		   </section>
		}}
		{{
			#selection{::log 
				<category>
					<item id='city'>::log::0</item>
					<item id='town'>::log::1</item>
				</category>
			}
		}}
		{{
			#selection{::extras 
				<category>
					<item id='city'>::extras::city</item>
					<item id='town'>::extras::town</item>
				</category>
			}
		}}
		{{
			<infoGroup>
				<info id='::extras#key'> 
					#collections{::dates <datetime>::dates#value</datetime> }  
					{{
						#selection{::extras 
							<category>
								<item id='city'>::extras::city</item>
								<item id='town'>::extras::town</item>
							</category>
						}
					}}		
				</info> 
			</infoGroup>
		}}
	{{ </article> }}""");

	assert(moose.render({
		'name':'john',
		'details':{'name':'john skatis','age':27,'from':'bordermoth'},
		'entry': 3,
		'log':['rice','baking'],
		'extras':{'city':'grouper','town':'centro'},
		'cop':{'city':'grouper','town':'centro'},
		'dates':['2013/3/43','3232/32/3101','1023/23/21']
	}).length > 30);

}