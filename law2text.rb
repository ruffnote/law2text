require 'bundler'
Bundler.require

require 'open-uri'

require 'active_support'
require 'active_support/core_ext'

HTML = './law.html'
TEXT = './law.txt'
PREFIX = 'keiho_'
URL = 'http://law.e-gov.go.jp/htmldata/M40/M40HO045.html'

HEAD = '<B>刑法<BR>
（明治四十年四月二十四日法律第四十五号）</B><BR><BR><DIV ALIGN="right">最終改正：平成二五年一一月二七日法律第八六号</DIV><BR><DIV ALIGN="right"><TABLE WIDTH="" BORDER="0"><TR><TD><FONT COLOR="RED">（最終改正までの未施行法令）</FONT></TD></TR><TR><TD>'


TAIL = '<B>第十六条</B>
　この法律の施行前に附則第二条の規定による改正前の刑法第二百八条の二（附則第十四条の規定によりなお従前の例によることとされる場合における当該規定を含む。）の罪を犯した者に対する附則第五条の規定による改正後の出入国管理及び難民認定法第五条第一項第九号の二、第二十四条第四号の二、第二十四条の三第三号、第六十一条の二の二第一項第四号及び第六十一条の二の四第一項第七号の規定の適用については、これらの規定中「第十六条の罪又は」とあるのは「第十六条の罪、」と、「第六条第一項」とあるのは「第六条第一項の罪又は同法附則第二条の規定による改正前の刑法第二百八条の二（自動車の運転により人を死傷させる行為等の処罰に関する法律附則第十四条の規定によりなお従前の例によることとされる場合における当該規定を含む。）」とする。
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
File.write(HTML, content)
