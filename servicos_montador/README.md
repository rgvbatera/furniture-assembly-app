# Furniture Services App

A Flutter application for managing furniture assembly services, including customer registration, scheduling, local storage, and PDF document generation.

## Features

### Implemented

- **Customer registration**: Add customers with name, address, service value, and scheduled date/time.
- **Customer list**: View pending and completed services with filters.
- **Schedule**: Browse appointments by date.
- **Local database**: Offline storage using SQLite.
- **PDF generation**: Create service documents that can be shared.
- **Responsive interface**: Material-based UI for mobile usage.

### In Progress

- **Calendar integration**: Sync appointments with the device calendar.
- **Notifications**: Appointment reminders.
- **Cloud backup**: Optional data synchronization.

## Project Structure

```text
lib/
├── models/
│   └── cliente.dart              # Customer data model
├── database/
│   └── database_helper.dart      # SQLite database helper
├── screens/
│   ├── home_screen.dart          # Main screen
│   ├── cadastro_cliente_screen.dart  # Customer create/edit screen
│   ├── lista_clientes_screen.dart    # Customer list
│   ├── agenda_screen.dart        # Schedule view
│   └── detalhes_cliente_screen.dart  # Customer details
├── services/
│   └── pdf_service.dart          # PDF generation service
└── main.dart                     # App entry point
```

## Usage

### Home Screen

- View the daily summary with appointments and values.
- Access the main workflows quickly.
- See today's and upcoming appointments.

### Customer Registration

1. Tap the `+` button to add a customer.
2. Fill in the required fields:
   - First and last name
   - Full address
   - Service value
   - Scheduled date and time
3. Save the customer.

### Appointment Management

- **Pending**: Services that have not been completed yet.
- **Completed**: Finished services.
- **Overdue**: Late appointments highlighted in the UI.
- **Upcoming**: Appointments scheduled for the next few hours.

### PDF Generation

1. Mark a service as completed.
2. Open the customer details screen.
3. Tap `Generate Invoice`.
4. The PDF is created and can be shared.

## Installation

### Requirements

- Flutter SDK 3.8.1 or newer
- Android Studio or VS Code
- Android device or emulator

### Setup

```bash
flutter pub get
flutter run
```

### Build a Debug APK

```bash
flutter build apk --debug
```

## Main Dependencies

- `sqflite`: Local SQLite database.
- `pdf` and `printing`: PDF creation and printing.
- `intl`: Date and number formatting.
- `device_calendar`: Device calendar integration.
- `share_plus`: File sharing.
- `path_provider`: Access to app storage directories.

## Android Configuration

The app requests these Android permissions:

- `READ_CALENDAR` and `WRITE_CALENDAR` for calendar integration.
- `WRITE_EXTERNAL_STORAGE` and `READ_EXTERNAL_STORAGE` for PDF storage on older Android versions.
- `INTERNET` for future online features.

## Company Data

The PDF template uses placeholder company data. To customize it, edit `lib/services/pdf_service.dart`:

```dart
static const String nomeEmpresa = 'Company Name';
static const String cnpjEmpresa = '00.000.000/0000-00';
static const String cidadeEmpresa = 'City - State - ZIP';
static const String telefoneEmpresa = '(00) 00000-0000';
static const String emailEmpresa = 'contact@example.com';
```

## Roadmap

### Version 2.0

- [ ] Full calendar integration
- [ ] Push notifications
- [ ] Cloud backup
- [ ] Financial reports
- [ ] Multiple service types
- [ ] Work completion photos

### Version 3.0

- [ ] iOS app support
- [ ] Multi-device synchronization
- [ ] Web dashboard
- [ ] Integration API

## Support

For issues or questions:

1. Check the source code documentation.
2. Review Flutter logs.
3. Open an issue in the repository.


