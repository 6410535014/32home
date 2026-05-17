# Admin CLI

A command-line tool for managing users, polls, and account balances via Firebase.

## Setup

### 1. Install dependencies
```bash
npm install
```

### 2. Add the Firebase service account key
This project requires a `serviceAccountKey.json` file to connect to Firebase. This file is **not included in the repository** for security reasons.

To get it:
1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project → Project Settings → Service Accounts
3. Click **Generate new private key** and download the file
4. Rename it to `serviceAccountKey.json` and place it in this folder

> ⚠️ Never commit `serviceAccountKey.json` to git.

---

## Usage

### User Management
```bash
# Create a new user
node user-manager.js add "+66812345678" "สมชาย ใจดี" "123/45"

# Delete a user
node user-manager.js delete "+66812345678"
```

### Update Balance
```bash
# Import balance data from a CSV file
node update-balance.js data.csv
```

The CSV file must have the following columns (row 1 = header, row 2 onward = data):

| Column | Description | Example |
|---|---|---|
| `Date` | Transaction date | `2025-01-15` |
| `Description` | Label for the transaction | `ค่าน้ำประจำเดือน` |
| `Income` | Income amount (leave blank if expense) | `1000` |
| `Expense` | Expense amount (leave blank if income) | `500` |
| `Category` | Category label (optional) | `สาธารณูปโภค` |
| `Evidence Link` | URL to receipt/slip (optional) | `https://drive.google.com/...` |

**Template (`data.csv`):**
```
Date,Description,Income,Expense,Category,Evidence Link
2025-01-15,ค่าน้ำประจำเดือน,,500,สาธารณูปโภค,https://drive.google.com/...
2025-01-15,เงินค่าส่วนกลาง,1000,,,
```

> - Use only `Income` **or** `Expense` per row, not both.
> - Date format must be `YYYY-MM-DD`.
> - Amounts can use commas (e.g. `1,000`) or plain numbers.

### Poll Management
```bash
# Create a new poll
node poll-manager.js create "[หัวข้อ]" "[รายละเอียด]" "[ค่าใช้จ่าย]" "[yyyy-mm-dd hh:mm]"

# List all polls
node poll-manager.js list

# View poll details
node poll-manager.js view [ID]

# Announce poll result
node poll-manager.js announce [ID]
```
