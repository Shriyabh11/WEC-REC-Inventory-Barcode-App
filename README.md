# WEC-REC Inventory Barcode App

A lightweight inventory management app for small sellers, built with **Flutter** (mobile), **Flask** (backend), and **SQLite/Postgres**.  
Track products, receive and dispatch items with barcodes, and get low-stock alerts—all with a minimal, reliable workflow.

---

## Features

- **User Authentication:**  
  Secure login/signup with JWT. Each user sees only their own products and items.

- **Product Management:**  
  - Add products with name, description, image, and low-stock threshold.
  - Images are uploaded and displayed in the app.

- **Receiving Items:**  
  - Receive (add) single items to a product.
  - Each received item generates a unique barcode (QR/Code128) encoding `{userId|productId|itemId}`.
  - Barcode preview and save/print option.

- **Dispatching Items:**  
  - Scan barcode to dispatch (remove) a single item.
  - Prevents double-dispatch via item status check.

- **Low-Stock Alerts:**  
  - Set per-product thresholds.
  - Get alerts when stock falls below threshold.

---

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Flask (Python)
- **Database:** SQLite (default, easy to switch to Postgres)
- **Authentication:** JWT
- **Image Uploads:** Multipart/form-data, served from Flask static folder

---

## Getting Started

### Prerequisites

- Flutter SDK (3.x recommended)
- Python 3.8+
- pip (Python package manager)

### Backend Setup

1. **Install dependencies:**
    ```bash
    cd backend
    pip install -r requirements.txt
    ```

2. **Configure environment:**
    - Copy `.env.example` to `.env` and set your secret key and DB path.

3. **Run the backend:**
    ```bash
    python app.py
    ```
    - The API will be available at `http://localhost:5000/`

### Frontend Setup

1. **Install dependencies:**
    ```bash
    cd frontend/inventory_tracker
    flutter pub get
    ```

2. **Run the app:**
    ```bash
    flutter run
    ```
    - For Android emulator, images are loaded from `http://10.0.2.2:5000/`
    - For iOS simulator or real device, adjust the backend URL if needed.

---

## Folder Structure

```
backend/
  app.py
  routes/
  static/product_images/
  utils.py
  ...
frontend/inventory_tracker/
  lib/
    data/
    domain/
    presentation/
    ...
```

---

## Usage

1. **Sign up or log in.**
2. **Add a product** (name, description, image, threshold).
3. **Receive items**: Select a product, receive an item, and get a barcode.
4. **Dispatch items**: Scan a barcode to dispatch an item.
5. **Monitor stock**: Get alerts when products are low on stock.

---

## Customization

- **Database:**  
  Default is SQLite. To use Postgres, update the DB connection in `backend/utils.py`.

- **Barcode Type:**  
  QR and Code128 supported. See `utils.py` for barcode generation logic.

---

## License

MIT License

---

## Credits

- Flutter, Flask, SQLite/Postgres, JWT, and open-source barcode libraries.

---

**Made for small sellers who want simple, reliable inventory management.**