blog
# blogcomment

```js
// Support To-Do List
modify  hexo-render-kramed lib/renderer.js
Renderer.prototype.listitem = function(text) {
  if (/^\s*\[[x ]\]\s*/.test(text)) {
    text = text.replace(/^\s*\[ \]\s*/, '<input type="checkbox"></input> ').replace(/^\s*\[x\]\s*/, '<input type="checkbox" checked></input> ');
    return '<li style="list-style: none">' + text + '</li>\n';
  } else {
    return '<li>' + text + '</li>\n';
  }
};
```