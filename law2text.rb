require 'bundler'
Bundler.require

require 'open-uri'

require 'active_support'
require 'active_support/core_ext'

HTML = './law.html'
TEXT = './law.txt'
PREFIX = 'minpo_'
URL = 'http://law.e-gov.go.jp/htmldata/M29/M29HO089.html'

HEAD = '<P>　　<B><A NAME="1001000000000000000000000000000000000000000000000000000000000000000000000000000">第一編　総則</A>
</B>'
TAIL = '<A NAME="1000000000000000000000000000000000000000000000104400000000001000000000000000000"></A>
　第八百八十七条第二項及び第三項、第九百条、第九百一条、第九百三条並びに第九百四条の規定は、遺留分について準用する。 
</DIV>'

unless File.exists?(HTML)
  content = open(URL, 'r:CP932').read
  content = content.encode('UTF-8')
  content.gsub!(/\A.+(#{Regexp.escape(HEAD)})/m, '\1')
  content.gsub!(/(#{Regexp.escape(TAIL)}).+\z/m, '\1')
  File.write(HTML, content)
end

content = File.read(HTML)
content = content.zen_to_i

doc = Nokogiri::HTML.fragment(content)

# dt: 編・章
doc.css(':not(.item) a').each do |node|
  if node[:name].present?
    unless node.content.strip =~ /\A\d+\z/ # 数字のみは項
      node.replace("<dt>#{node.content}</dt>")
    end
  end
end

# dt: 条・項
item = nil
doc.css('.item').each do |node|
  node.css('b').each do |node|
    if node.content =~ /条/
      node.replace("<dt>#{node.content}</dt>")
      item = node.content
    end
  end
  node.css('a').each do |node|
    if node.content.strip =~ /\A\d+\z/ # 数字のみは項
      node.replace("<dt>#{item}#{node.content}項</dt>")
    end
  end
end

# dd: 条・項
content = doc.to_html
content.gsub!(%r{((:?条|項)</dt>)}, '\1<dd>')
content.gsub!(%r{(<dd>.*?)(<dt>)}m, '\1</dd>\2')

# 不要なタグ削除
content.gsub!(%r{</?p>|</?b>|</?a[^>]*>|</?div[^>]*>}, '')

# class: 条・項
doc = Nokogiri::HTML.fragment(content)
doc.css('dt').each do |node|
  if node.content =~ /条|項/
    node[:class] = "#{PREFIX}#{node.content.scan(/\d+/).join('_')}"
  end
end

content = doc.to_html
content = "<dl>#{content}</dl>"

File.write(TEXT, content)
File.write(HTML2, content)
