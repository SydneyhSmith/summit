const http = require('http')
const fs = require('fs')
const path = require('path')

const PORT = process.env.PORT || 8080
const PUBLIC = path.join(__dirname, 'public')

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
}

http.createServer((req, res) => {
  let filePath = path.join(PUBLIC, req.url === '/' ? 'index.html' : req.url)

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404)
      res.end('Not found')
      return
    }
    const ext = path.extname(filePath)
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' })
    res.end(data)
  })
}).listen(PORT, () => console.log(`Summit site running on port ${PORT}`))
