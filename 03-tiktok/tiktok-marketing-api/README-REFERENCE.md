# TikTok Marketing API

## Status: 🔲 PENDING — No official OpenAPI spec published

TikTok does not publish their Marketing API as an OpenAPI spec on GitHub.
Their documentation is available at:

- **Business API Portal**: https://business-api.tiktok.com/portal/docs/id/1739584855420929
- **Sandbox**: https://business-api.tiktok.com/portal/docs/id/1735791367990786
- **Postman Collection**: Available inside the TikTok Business Center

### Key Endpoints (from docs, not official spec)

| Category | Endpoints | Description |
|---|---|---|
| **Advertiser** | GET /advertiser/info/ | Account info |
| **Campaign** | CRUD /campaign/ | Campaign management |
| **Ad Group** | CRUD /adgroup/ | Ad set management |
| **Ad** | CRUD /ad/ | Ad management |
| **Creative** | POST /creative/ | Creative assets |
| **Reporting** | GET /report/integrated/get/ | Performance data |
| **Audience** | CRUD /audience/ | Custom audiences |
| **Lead** | GET /lead/ | Lead generation data |

### When to Document
- When TikTok publishes an official OpenAPI spec
- Or when ALIUN activates TikTok Ads as a traffic source
- Manual GTI creation from portal docs is possible but not prioritized

### Authentication
- OAuth 2.0 via TikTok Business Center
- Access Token + Advertiser ID required
