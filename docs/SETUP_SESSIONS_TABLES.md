# Supabase Sessions Table Setup Instructions

## Problem
The Jammer App is getting **404 Not Found** errors when trying to create sessions because the tables don't exist in Supabase yet.

## Solution
Run the SQL schema in your Supabase project to create the necessary tables.

## Step-by-Step Instructions

### 1. Go to Supabase Dashboard
- Navigate to https://app.supabase.com
- Select your **Jammer App** project
- Go to **SQL Editor** (left sidebar)

### 2. Run the Complete Sessions Schema
- Click **"New Query"**
- Copy the entire contents of **`supabase_sessions_complete.sql`** (in the `docs/` folder)
- Paste into the SQL editor
- Click **"RUN"**

### 3. Verify Table Creation
After running the SQL, you should see:
- ✅ **sessions** table created with columns: id, user_id, name, session_date, notes, created_at, updated_at
- ✅ **session_songs** table created with columns: session_id, document_id, user_id, sort_order
- ✅ RLS (Row Level Security) policies enabled for both tables
- ✅ Indexes created for performance
- ✅ Auto-update trigger for `sessions.updated_at`

### 4. Test the Setup
Go back to the Jammer App and:
1. Create a new session (click "Create Session" button)
2. Fill in the form and submit
3. The session should be created successfully (no more 404 error)

## Table Relationships

```
┌─────────────────────┐
│     auth.users      │
│   (id: uuid)        │
└──────────┬──────────┘
           │
           ├──→ sessions (user_id)
           │    └──→ session_songs (session_id)
           │         └──→ documents (document_id)
           │
           └──→ documents (user_id)
                └──→ session_songs (document_id)
```

**sessions table** - Stores jam sessions with optional dates and notes
**session_songs table** - Junction table linking sessions to documents (songs) with ordered setlist

## What Was Created

### Tables
- **sessions**: Practice/jam sessions with date, name, and notes
- **session_songs**: Ordered setlist of documents (songs) in each session

### Security (RLS Policies)
- Users can only see/modify their own sessions and session songs
- Enforced at the database level

### Performance (Indexes)
- Fast lookups by user, session, and document
- Ordered queries for setlists

### Automation
- Auto-timestamp updates to `sessions.updated_at` when sessions change

## Troubleshooting

**If you get an error about duplicate tables:**
- The schema includes `CREATE TABLE IF NOT EXISTS`, so it's safe to run multiple times

**If the 404 persists after running the schema:**
1. Refresh your Flutter app (hot reload or hot restart)
2. Check Supabase dashboard to confirm tables exist
3. Verify your Supabase credentials in `.env` file match the project
4. Check the app's debug console for the actual error message

**To check your Supabase project setup:**
- Go to **SQL Editor** → **Saved queries** → scroll down to see existing tables
- Or go to **Database** → **Tables** to see all tables in your project
