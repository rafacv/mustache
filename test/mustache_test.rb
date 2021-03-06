# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.dirname(__FILE__)
require 'helper'

class MustacheTest < Test::Unit::TestCase
  def test_instance_render
    klass = Class.new(Mustache)
    klass.template = "Hi {{thing}}!"
    assert_equal "Hi world!", klass.render(:thing => :world)
    assert_equal "Nice.", klass.render("{{compliment}}.", :compliment => "Nice")
    assert_equal <<-end_simple, Simple.new.render(:name => "yo", :in_ca => false)
Hello yo
You have just won $10000!
end_simple
  end

  def test_passenger
    assert_equal <<-end_passenger, Passenger.to_text
<VirtualHost *>
  ServerName example.com
  DocumentRoot /var/www/example.com
  RailsEnv production
</VirtualHost>
end_passenger
  end

  def test_complex_view
    assert_equal <<-end_complex, ComplexView.render
<h1>Colors</h1>
  <ul>
      <li><strong>red</strong></li>
      <li><a href="#Green">green</a></li>
      <li><a href="#Blue">blue</a></li>
  </ul>

end_complex
  end

  def test_nested_objects
    assert_equal <<-end_complex, NestedObjects.render
<h1>Colors</h1>
  <ul>
      <li><strong>red</strong></li>
      <li><a href="#Green">green</a></li>
      <li><a href="#Blue">blue</a></li>
  </ul>

end_complex
  end

  def test_single_line_sections
    html = %(<p class="flash-notice" {{# no_flash }}style="display: none;"{{/ no_flash }}>)

    instance = Mustache.new
    instance.template = html
    instance[:no_flash] = true
    assert_equal %Q'<p class="flash-notice" style="display: none;">', instance.render
  end

  def test_sassy_single_line_sections
    instance = Mustache.new
    instance[:full_time] = true
    instance.template = "\n {{#full_time}}full time{{/full_time}}\n"

    assert_equal "\n full time\n", instance.render
  end

  def test_two_line_sections
    html = %(<p class="flash-notice" {{# no_flash }}style="display: none;"\n{{/ no_flash }}>)

    instance = Mustache.new
    instance.template = html
    instance[:no_flash] = true
    assert_equal %Q'<p class="flash-notice" style="display: none;"\n>', instance.render
  end

  def test_multi_line_sections_preserve_trailing_newline
    view = Mustache.new
    view.template = <<template
{{#something}}
yay
{{/something}}
Howday.
template

    view[:something] = true
    assert_equal <<-rendered, view.render
yay
Howday.
rendered
  end

  def test_single_line_inverted_sections
    html = %(<p class="flash-notice" {{^ flash }}style="display: none;"{{/ flash }}>)

    instance = Mustache.new
    instance.template = html
    assert_equal %Q'<p class="flash-notice" style="display: none;">', instance.render
  end

  def test_simple
    assert_equal <<-end_simple, Simple.render
Hello Chris
You have just won $10000!
Well, $6000.0, after taxes.
end_simple
  end

  def test_hash_assignment
    view = Simple.new
    view[:name]  = 'Bob'
    view[:value] = '4000'
    view[:in_ca] = false

    assert_equal <<-end_simple, view.render
Hello Bob
You have just won $4000!
end_simple
  end

  def test_crazier_hash_assignment
    view = Simple.new
    view[:name]  = 'Crazy'
    view[:in_ca] = [
      { :taxed_value => 1 },
      { :taxed_value => 2 },
      { :taxed_value => 3 },
    ]

    assert_equal <<-end_simple, view.render
Hello Crazy
You have just won $10000!
Well, $1, after taxes.
Well, $2, after taxes.
Well, $3, after taxes.
end_simple
  end

  def test_fileless_templates
    view = Simple.new
    view.template = 'Hi {{person}}!'
    view[:person]  = 'mom'

    assert_equal 'Hi mom!', view.render
  end

  def test_delimiters
    assert_equal <<-end_template, Delimiters.render
* It worked the first time.
* And it worked the second time.
* As well as the third.
* Then, surprisingly, it worked the final time.
end_template
  end

  def test_double_section
    assert_equal <<-end_section, DoubleSection.render
  * first
* second
  * third
end_section
  end

  def test_inverted_section
    assert_equal <<-end_section, InvertedSection.render
  * first
* second
  * third
end_section
  end

  def test_comments
    assert_equal "<h1>A Comedy of Errors</h1>\n", Comments.render
  end

  def test_multi_linecomments
    view = Comments.new
    view.template = "<h1>{{title}}{{! just something interesting... \n#or not... }}</h1>\n"
    assert_equal "<h1>A Comedy of Errors</h1>\n", view.render
  end

  def test_escaped
    assert_equal '<h1>Bear &gt; Shark</h1>', Escaped.render
  end

  def test_unescaped
    assert_equal '<h1>Bear > Shark</h1>', Unescaped.render
  end

  def test_unescaped_ampersand
    view = Mustache.new
    view.template = "<h1>{{& title}}</h1>"
    view[:title] = "Bear > Shark"
    assert_equal '<h1>Bear > Shark</h1>', view.render
  end

  def test_classify
    assert_equal 'TemplatePartial', Mustache.classify('template_partial')
  end

  def test_underscore
    assert_equal 'template_partial', Mustache.underscore('TemplatePartial')
  end

  def test_anon_subclass_underscore
    klass = Class.new(TemplatePartial)
    assert_equal 'template_partial', klass.underscore
  end

  def test_namespaced_underscore
    assert_equal 'stat_stuff', Mustache.underscore('Views::StatStuff')
  end

  def test_render
    assert_equal 'Hello World!', Mustache.render('Hello World!')
  end

  def test_render_with_params
    assert_equal 'Hello World!', Mustache.render('Hello {{planet}}!', :planet => 'World')
  end

  def test_render_from_file
    expected = <<-data
<VirtualHost *>
  ServerName example.com
  DocumentRoot /var/www/example.com
  RailsEnv production
</VirtualHost>
data
    template = File.read(File.dirname(__FILE__) + "/fixtures/passenger.conf")
    assert_equal expected, Mustache.render(template, :stage => 'production',
                                                     :server => 'example.com',
                                                     :deploy_to => '/var/www/example.com' )
  end

  def test_doesnt_execute_what_it_doesnt_need_to
    instance = Mustache.new
    instance[:show] = false
    instance.instance_eval do
      def die
        raise "bummer"
      end
    end
    instance.template = '{{#show}} <li>{{die}}</li> {{/show}} yay'

    assert_equal " yay", instance.render
  end

  def test_reports_unclosed_sections
    instance = Mustache.new
    instance[:list] = [ :item => 1234 ]
    instance.template = '{{#list}} <li>{{item}}</li> {{/gist}}'

    begin
      instance.render
    rescue => e
    end

    assert e.message.include?('Unclosed section')
  end

  def test_unclosed_sections_reports_the_line_number
    instance = Mustache.new
    instance[:list] = [ :item => 1234 ]
    instance.template = "hi\nmom\n{{#list}} <li>{{item}}</li> {{/gist}}"

    begin
      instance.render
    rescue => e
    end

    assert e.message.include?('Line 3')
  end

  def test_enumerable_sections_accept_a_hash_as_a_context
    instance = Mustache.new
    instance[:list] = { :item => 1234 }
    instance.template = '{{#list}} <li>{{item}}</li> {{/list}}'

    assert_equal ' <li>1234</li> ', instance.render
  end

  def test_enumerable_sections_accept_a_string_keyed_hash_as_a_context
    instance = Mustache.new
    instance[:list] = { 'item' => 1234 }
    instance.template = '{{#list}} <li>{{item}}</li> {{/list}}'

    assert_equal ' <li>1234</li> ', instance.render
  end

  def test_not_found_in_context_renders_empty_string
    instance = Mustache.new
    instance.template = '{{#list}} <li>{{item}}</li> {{/list}}'

    assert_equal '', instance.render
  end

  def test_not_found_in_nested_context_renders_empty_string
    instance = Mustache.new
    instance[:list] = { :item => 1234 }
    instance.template = '{{#list}} <li>{{prefix}}{{item}}</li> {{/list}}'

    assert_equal ' <li>1234</li> ', instance.render
  end

  def test_not_found_in_context_raises_when_asked_to
    instance = Mustache.new
    instance.raise_on_context_miss = true
    instance.template = '{{#list}} <li>{{item}}</li> {{/list}}'

    assert_raises Mustache::ContextMiss do
      instance.render
    end
  end

  def test_knows_when_its_been_compiled_when_set_with_string
    klass = Class.new(Mustache)

    assert ! klass.compiled?
    klass.template = 'Hi, {{person}}!'
    assert klass.compiled?
  end

  def test_knows_when_its_been_compiled_when_using_a_file_template
    klass = Class.new(Simple)
    klass.template_file = File.dirname(__FILE__) + '/fixtures/simple.mustache'

    assert ! klass.compiled?
    klass.render
    assert klass.compiled?
  end

  def test_an_instance_knows_when_its_class_is_compiled
    instance = Simple.new

    assert ! Simple.compiled?
    assert ! instance.compiled?

    Simple.render

    assert Simple.compiled?
    assert instance.compiled?
  end

  def test_knows_when_its_been_compiled_at_the_instance_level
    klass = Class.new(Mustache)
    instance = klass.new

    assert ! instance.compiled?
    instance.template = 'Hi, {{person}}!'
    assert instance.compiled?
  end

  def test_sections_returning_lambdas_get_called_with_text
    view = Lambda.new
    view[:name] = 'Chris'

    assert_equal "Hi Chris.\n\nHi {{name}}.", view.render.chomp
    assert_equal 1, view.calls

    assert_equal "Hi Chris.\n\nHi {{name}}.", view.render.chomp
    assert_equal 1, view.calls

    assert_equal "Hi Chris.\n\nHi {{name}}.", view.render.chomp
    assert_equal 1, view.calls
  end

  def test_lots_of_staches
    template = "{{{{foo}}}}"

    begin
      Mustache.render(template, :foo => "defunkt")
    rescue => e
    end

    assert e.message.include?("Illegal content in tag")
  end

  def test_liberal_tag_names
    template = "{{first-name}} {{middle_name!}} {{lastName?}}"
    hash = {
      'first-name' => 'chris',
      'middle_name!' => 'j',
      'lastName?' => 'strath'
    }

    assert_equal "chris j strath", Mustache.render(template, hash)
  end

  def test_nested_sections_same_names
    template = <<template
{{#items}}
start
{{#items}}
{{a}}
{{/items}}
end
{{/items}}
template

    data = {
      "items" => [
        { "items" => [ {"a" => 1}, {"a" => 2}, {"a" => 3} ] },
        { "items" => [ {"a" => 4}, {"a" => 5}, {"a" => 6} ] },
        { "items" => [ {"a" => 7}, {"a" => 8}, {"a" => 9} ] }
      ]
    }

    assert_equal <<expected, Mustache.render(template, data)
start
1
2
3
end
start
4
5
6
end
start
7
8
9
end
expected
  end

  def test_id_with_nested_context
    html = %(<div>{{id}}</div>\n<div>{{# has_a? }}{{id}}{{/ has_a? }}</div>\n<div>{{# has_b? }}{{id}}{{/ has_b? }}</div>\n)

    instance = Mustache.new
    instance.template = html
    instance[:id] = 3
    instance[:has_a?] = true
    instance[:has_b?] = true
    assert_equal <<-rendered, instance.render
<div>3</div>
<div>3</div>
<div>3</div>
rendered
  end

  def test_utf8
    klass = Class.new(Mustache)
    klass.template_name = 'utf8'
    klass.template_path = 'test/fixtures'
    view = klass.new
    view[:test] = "中文"

    assert_equal <<-rendered, view.render
<h1>中文 中文</h1>

<h2>中文又来啦</h2>
rendered
  end

  def test_indentation
    view = Mustache.new
    view[:name] = 'indent'
    view[:text] = 'puts :indented!'
    view.template = <<template
def {{name}}
  {{text}}
end
template

  assert_equal <<template, view.render
def indent
  puts :indented!
end
template
  end

  def test_inherited_attributes
    Object.const_set :TestNamespace, Module.new
    base = Class.new(Mustache)
    tmpl = Class.new(base)

    {:template_path      => File.expand_path('./foo'),
     :template_extension => 'stache',
     :view_namespace     => TestNamespace,
     :view_path          => './foo'
     }.each do |attr, value|
      base.send("#{attr}=", value)
      assert_equal value, tmpl.send(attr)
    end
  end
    def test_array_of_arrays
    template = <<template
{{#items}}
start
{{#map}}
{{a}}
{{/map}}
end
{{/items}}
template

    data = {
      "items" => [
        [ {"a" => 1}, {"a" => 2}, {"a" => 3} ],
        [ {"a" => 4}, {"a" => 5}, {"a" => 6} ],
        [ {"a" => 7}, {"a" => 8}, {"a" => 9} ]
      ]
    }

    assert_equal <<expected, Mustache.render(template, data)
start
1
2
3
end
start
4
5
6
end
start
7
8
9
end
expected
  end
      def test_indentation_again
    template = <<template
SELECT
  {{#cols}}
    {{name}},
  {{/cols}}
FROM
  DUMMY1
template

    view = Mustache.new
    view[:cols] = [{:name => 'Name'}, {:name => 'Age'}, {:name => 'Weight'}]
    view.template = template

    assert_equal <<template, view.render
SELECT
    Name,
    Age,
    Weight,
FROM
  DUMMY1
template
  end
end
