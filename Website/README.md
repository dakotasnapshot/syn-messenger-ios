# SYN Messenger website

Publish `public/` at `https://synmessenger.com/`. Configure extensionless routes for `/privacy`, `/terms`, and `/support`, or redirect those paths to their `.html` files.

Serve `.well-known/apple-app-site-association` with `Content-Type: application/json`, no redirects, and no filename extension. Apple must be able to fetch it over valid HTTPS.

Production is an ISPConfig-managed static site. Install
`apache-synmessenger.com-le-ssl.conf` as the Apache TLS vhost after Certbot has
issued the `synmessenger.com` certificate. Mail remains hosted by Mail-in-a-Box.

SYN Web lives at `/chat/` and currently uses Element Web `v1.12.27` (`element-v1.12.27.tar.gz`, SHA-256 `0b3a3e3211155dbed31fad1413d09972edd3ce715e778189b1ad460a56e28bb8`). Install the release contents in `public/chat/`, replace its `config.json` with `element-web-config.json`, replace its `manifest.json` with `element-web-manifest.json`, point favicon and Apple touch icon tags in its `index.html` to `/syn-icons/`, preserve upstream license files, and deploy the static tree with the rest of the site.

Copy `element-web-mobile-bootstrap.js` into the web root and load it before Element's bundle script. Upstream redirects mobile browsers to `mobile_guide/` before configuration loads; the bootstrap opts into full web mode for SYN.
