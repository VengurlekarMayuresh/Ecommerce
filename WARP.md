# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Project overview
- Monorepo with two apps:
  - client/ — React 19 + Vite + Redux Toolkit + Tailwind; SPA config in client/staticwebapp.config.json (fallback to index.html, simple /api/* allow-list).
  - server/ — Node.js + Express + MongoDB/Mongoose; Azure integrations (Application Insights, Blob Storage, optional Key Vault, PayPal).
- Frontend API calls are hardcoded to http://localhost:5000/... across slices (no env-based baseURL). For production, update these URLs or introduce a configurable base URL.

Common commands
- Install
  - client: npm install (run in client/)
  - server: npm install (run in server/)
- Develop (two terminals)
  - server (Express, hot reload):
    ```bash path=null start=null
    cd server
    npm run dev
    ```
  - client (Vite dev server):
    ```bash path=null start=null
    cd client
    npm run dev
    ```
- Run server without nodemon
  ```bash path=null start=null
  cd server
  npm start
  ```
- Lint (frontend only)
  ```bash path=null start=null
  cd client
  npm run lint
  ```
- Build/preview (frontend)
  ```bash path=null start=null
  cd client
  npm run build
  npm run preview
  ```
- Docker (backend)
  ```bash path=null start=null
  cd server
  docker build -t ecommerce-server:latest .
  # Container exposes 8080, map it to 5000 for local parity
  docker run -p 5000:8080 --env-file .env ecommerce-server:latest
  ```

Environment
- Backend (server/.env) — keys referenced in README:
  ```env path=null start=null
  MONGO_DBURL=...
  SECRET_KEY=...
  APPLICATIONINSIGHTS_CONNECTION_STRING=...
  AZURE_STORAGE_CONNECTION_STRING=...
  CLIENT_URL=http://localhost:5173
  CLOUDINARY_CLOUD_NAME=...
  CLOUDINARY_API_KEY=...
  CLOUDINARY_API_SECRET=...
  PAYPAL_CLIENT_ID=...
  PAYPAL_CLIENT_SECRET=...
  ```
- Frontend (client/.env) — not currently used by code for API base, but Vite var stub exists:
  ```env path=null start=null
  VITE_API_URL=http://localhost:5000/api
  ```

CI/CD (GitHub Actions)
- Backend deploy: .github/workflows/azure-deploy-backend.yml
  - Triggers: push to main/master/external with changes under server/ (or manual dispatch)
  - Builds a production zip of server/ and deploys via azure/webapps-deploy@v2 to app-name: ecomm-app-4379
  - Required secret: AZURE_WEBAPP_PUBLISH_PROFILE (App Service publish profile XML)
  - Health check: GET https://ecomm-app-4379.azurewebsites.net/api/health (10 attempts)
- An additional workflow exists at server/.github/workflows/azure-deploy.yml (branch: external) deploying the server tarball; ensure only one workflow targets the same app unless intentional.

Azure tips specific to this repo
- App Service logs
  ```bash path=null start=null
  az webapp log tail --name ecomm-app-4379 --resource-group <RESOURCE_GROUP>
  ```
- If the frontend is hosted on Azure Static Web Apps, you may need to:
  - Update client API URLs away from localhost, or
  - Introduce a baseURL read from Vite env and switch per environment, or
  - Configure SWA reverse proxy rules to the App Service.

Code architecture (big picture)
- client/
  - src/pages/* — route-level pages for shopping and admin views
  - src/components/* — UI components (admin-view, shopping-view, common, ui)
  - src/store/* — Redux slices (auth, cart, products, orders, address, search, payments)
  - src/config/index.js — UI form configs, filter/sort options
  - staticwebapp.config.json — SPA fallback, minimal /api/* allow-list
- server/
  - Entry: server.js (CommonJS). Scripts: dev (nodemon), start (node)
  - Dependencies: express, mongoose, multer, jsonwebtoken, PayPal SDK; Azure SDKs for identity, Key Vault, Blob; Application Insights
  - Expect conventional folders (controllers, routes, models, middleware, config) as referenced in README

Notes for future automation
- Tests: no test scripts are defined in client/server package.json.
- Linting: only configured in client via eslint.config.js.
- When adding a configurable API base URL on the client, prefer a single axios instance and Vite env (import.meta.env) to avoid scattering localhost URLs.
