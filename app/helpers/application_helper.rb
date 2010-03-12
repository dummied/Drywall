module ApplicationHelper
  def awesome_truncate(text, length = 30, truncate_string = " ...")
    return if text.nil?
    l = length - truncate_string.length
   text.length > l ? text[/\A.{#{l}}\w*\;?/m][/.*[\w\;]/m] + truncate_string : text
  end
end
