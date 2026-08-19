# JobTracker

A lightweight native macOS app for tracking job applications — company, role, req number, status, and the date you applied.

## Features

- Add, edit, and delete applications
- Filter by status (Applied, Interviewing, Offer, Rejected, Withdrawn) and search by company, role, or req number
- Print a formatted summary of your applications
- Data is stored locally as JSON in Application Support — nothing leaves your machine

## Requirements

- macOS 14 (Sonoma) or later
- Swift 5.10 toolchain (Xcode 15.4+ or a matching Swift toolchain)

## Building and Running

Run directly with Swift Package Manager:

```bash
swift run
```

Or build a double-clickable `.app` bundle:

```bash
./build_app.sh
```

This produces `JobTracker.app` in the project root.
