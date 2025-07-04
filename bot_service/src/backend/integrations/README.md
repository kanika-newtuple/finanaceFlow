# 📊 Google Sheets & Excel Integration

FinanceFlow now supports seamless integration with Google Sheets and Excel for advanced data analysis and sharing.

## 🚀 Features

### Google Sheets Integration
- **Real-time Export**: Export bills and transactions directly to Google Sheets
- **Auto-formatting**: Professional formatting with headers and colors
- **Multi-sheet Export**: Bills Summary, Transaction Details, and Analytics sheets
- **Live Sync**: Sync data with existing Google Sheets
- **Shareable**: Share financial data with team members instantly

### Excel Integration
- **Advanced Formatting**: Professional Excel files with multiple worksheets
- **Rich Analytics**: Built-in analytics summary with charts
- **Offline Access**: Download and work offline
- **Data Validation**: Proper formatting for currencies, dates, and numbers

## 🔧 Setup Instructions

### Google Sheets Setup

#### Step 1: Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note your project ID

#### Step 2: Enable Google Sheets API
1. Navigate to "APIs & Services" > "Library"
2. Search for "Google Sheets API"
3. Click "Enable"

#### Step 3: Create Credentials
1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. If prompted, configure the OAuth consent screen:
   - User Type: External (for testing) or Internal (for organization)
   - Add your email as a test user
4. Application type: "Desktop application"
5. Name: "FinanceFlow Integration"
6. Download the JSON credentials file

#### Step 4: Install Credentials
1. Save the downloaded JSON file as `google_credentials.json`
2. Place it in: `bot_service/src/backend/integrations/`
3. **Important**: Never commit this file to version control

#### Step 5: First-time Authorization
1. When you first use Google Sheets export, a browser window will open
2. Sign in with your Google account
3. Grant permissions to access your Google Sheets
4. The authorization token will be saved automatically

### Excel Setup
Excel integration works out of the box - no additional setup required!

## 📱 Using the Integration

### From the Dashboard
1. Navigate to the **Analytics** tab
2. Use the integration buttons:
   - **Export to Google Sheets**: Creates a new Google Sheet
   - **Export to Excel**: Downloads an Excel file
   - **Sync with Sheet**: Updates an existing Google Sheet

### From the Bills View
1. Navigate to the **Bills** tab
2. Use the quick export buttons in the toolbar:
   - **CSV**: Traditional CSV export
   - **Google Sheets**: Quick Google Sheets export
   - **Excel**: Quick Excel download

### API Endpoints

#### Export to Google Sheets
```bash
POST /api/v1/integrations/export/google-sheets
Content-Type: application/json

{
  "include_transactions": true,
  "include_analytics": true
}
```

#### Export to Excel
```bash
POST /api/v1/integrations/export/excel
Content-Type: application/json

{
  "filename": "custom_export.xlsx",
  "include_transactions": true,
  "include_analytics": true
}
```

#### Sync with Existing Google Sheet
```bash
POST /api/v1/integrations/sync/google-sheets/{spreadsheet_id}
```

## 📊 Export Content

### Bills Summary Sheet
- Vendor information and contact details
- Document metadata (dates, types, IDs)
- Financial totals and balances
- Payment terms and recipient info

### Transactions Detail Sheet
- Line-by-line transaction breakdown
- Categories and descriptions
- Quantities, unit prices, and totals
- Notes and table sections

### Analytics Sheet
- Key metrics summary
- Top vendors and amounts
- Monthly comparisons
- Export timestamps

## 🔒 Security & Privacy

### Google Sheets
- OAuth 2.0 authentication (industry standard)
- Credentials stored locally only
- No passwords stored in the application
- Revoke access anytime through Google Account settings

### Excel Files
- Generated locally on the server
- No data sent to third parties
- Files auto-deleted after download
- Secure file transfer

## 🛠 Troubleshooting

### Common Issues

#### "Failed to authenticate with Google Sheets"
- **Solution**: Ensure `google_credentials.json` is in the correct location
- Check that Google Sheets API is enabled in your Google Cloud project

#### "Spreadsheet not found" (Sync)
- **Solution**: Verify the Google Sheets ID in the URL
- Ensure you have edit permissions on the target sheet

#### "Export failed: Permission denied"
- **Solution**: Re-authorize the application
- Delete `token.json` and try again (will prompt for re-authorization)

#### Excel Download Not Working
- **Solution**: Check that the `exports` directory exists
- Verify write permissions on the server

### Getting the Google Sheets ID
The spreadsheet ID is in the URL:
```
https://docs.google.com/spreadsheets/d/SPREADSHEET_ID/edit
                                    ^^^^^^^^^^^^^^^^
```

## 🔄 Automatic Sync (Future Feature)
Planning to add:
- Scheduled sync (daily/weekly/monthly)
- Real-time updates when new bills are processed
- Webhook notifications
- Google Drive integration

## 📞 Support

For integration issues:
1. Check the application logs
2. Verify API permissions
3. Test with a fresh Google Cloud project
4. Contact support with error messages

## 🔗 Related Documentation
- [Google Sheets API Documentation](https://developers.google.com/sheets/api)
- [OAuth 2.0 Guide](https://developers.google.com/identity/protocols/oauth2)
- [FinanceFlow API Documentation](../docs/api.md) 