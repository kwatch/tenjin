LANGUAGES = [
  ['en', 'Engilish'],
  ['fr', 'French'],
  ['de', 'German'],
  ['es', 'Spanish'],
  ['ch', 'Chinese'],
  ['ja', 'Japanese'],
]

def link_to(label, options={})
  action, id = options[:action], options[:id]
  url = '/app'
  url << '/' << action if action && !action.empty?
  url << '/' << id     if id
  return "<a href=\"#{CGI::escape(url).gsub(/%2F/i, '/')}\">#{label}</a>"
end
