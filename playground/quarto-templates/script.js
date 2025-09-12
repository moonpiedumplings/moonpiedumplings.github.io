 const template = document.querySelector('[type="text/template"]')
  const result = document.querySelector('#result')
  const engine = new liquidjs.Liquid()

  engine
	.parseAndRender(template.innerHTML, {name: 'liquid'})
	.then(html => result.innerHTML = html)