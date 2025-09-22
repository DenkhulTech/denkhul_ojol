# OjolMVP - Ride-hailing Application Backend

> A comprehensive backend system for ride-hailing applications built with Phoenix/Elixir

[![Phoenix](https://img.shields.io/badge/Phoenix-1.8.1-orange.svg)](https://phoenixframework.org/)
[![Elixir](https://img.shields.io/badge/Elixir-1.18.2-purple.svg)](https://elixir-lang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-12+-blue.svg)](https://postgresql.org/)
[![WebSocket](https://img.shields.io/badge/WebSocket-Real--time-green.svg)](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API)

## 🚀 Overview

OjolMVP provides a robust backend infrastructure for ride-hailing applications featuring real-time order management, intelligent driver-customer matching, live GPS tracking, and bidirectional communication through WebSocket channels.

## 📋 Table of Contents

- [Features](#-features)
- [Technology Stack](#-technology-stack)
- [API Documentation](#-api-documentation)
- [WebSocket Schema](#-websocket-schema)
- [Database Schema](#-database-schema)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Contributing](#-contributing)

## ✨ Features

### Core Functionality

- **Complete CRUD Operations** for users, orders, and ratings
- **Real-time Communication** via Phoenix Channels/WebSocket
- **Live GPS Tracking** and location updates
- **Order Broadcasting** to available drivers
- **Rating System** for service quality feedback
- **Driver-Customer Matching** with distance-based filtering
- **Order Status Management** with complete workflow

### Order Workflow

```
pending → accepted → in_progress → completed
```

### User Types

- **Customers**: Request rides, track orders, rate drivers
- **Drivers**: Receive orders, update location, manage trips

## 🛠 Technology Stack

| Component              | Technology                      |
| ---------------------- | ------------------------------- |
| **Backend Framework**  | Phoenix 1.8.1                   |
| **Language**           | Elixir 1.18.2                   |
| **Database**           | PostgreSQL with Ecto ORM        |
| **Real-time**          | Phoenix Channels with WebSocket |
| **JSON Serialization** | Custom Decimal handling         |
| **Testing**            | Built-in ExUnit framework       |

## 📖 API Documentation

### 🌐 Swagger UI

Interactive API documentation is available at:
**[https://apijol.denkhultech.com/docs/ui](https://apijol.denkhultech.com/docs/ui)**

### Base URL

```
Production: https://apijol.denkhultech.com
Development: http://localhost:4000
```

### Standard CRUD Endpoints

#### Users Management

```http
GET    /api/users          # List all users
POST   /api/users          # Create new user
GET    /api/users/:id      # Get user by ID
PUT    /api/users/:id      # Update user
DELETE /api/users/:id      # Delete user
```

#### Orders Management

```http
GET    /api/orders         # List all orders
POST   /api/orders         # Create new order
GET    /api/orders/:id     # Get order by ID
PUT    /api/orders/:id     # Update order
DELETE /api/orders/:id     # Delete order
```

#### Ratings Management

```http
GET    /api/ratings        # List all ratings
POST   /api/ratings        # Create new rating
```

### Custom Ride-hailing Endpoints

#### Driver Operations

```http
GET  /api/orders/available           # Get available orders for drivers
PUT  /api/orders/:id/accept          # Driver accepts order
PUT  /api/orders/:id/start           # Start trip
PUT  /api/orders/:id/complete        # Complete trip
PUT  /api/users/:id/location         # Update driver location
```

### Example API Requests

#### Create New Order

```json
POST /api/orders
{
  "pickup_address": "Jl. Sudirman No. 1, Jakarta",
  "pickup_latitude": -6.208763,
  "pickup_longitude": 106.845599,
  "destination_address": "Mall Taman Anggrek, Jakarta",
  "destination_latitude": -6.178306,
  "destination_longitude": 106.791992,
  "customer_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

#### Update Driver Location

```json
PUT /api/users/:id/location
{
  "latitude": -6.200000,
  "longitude": 106.816666
}
```

## 🔌 WebSocket Schema

### Connection Setup

#### WebSocket URL

```
Production:  wss://apijol.denkhultech.com/socket/websocket
Development: ws://localhost:4000/socket/websocket
structuc url : ws://localhost:4000/socket/websocket?token=eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJvam9sX212cCIsImV4cCI6MTc2MDk3MzQ1NiwiaWF0IjoxNzU4NTU0MjU2LCJpc3MiOiJvam9sX212cCIsImp0aSI6IjZhMzc2MjY1LTc0ZTgtNDcwZS05NWYxLTJiMDViOTZjMzNkOCIsIm5iZiI6MTc1ODU1NDI1NSwic3ViIjoiMSIsInR5cCI6ImFjY2VzcyIsInR5cGUiOiJkcml2ZXIifQ.PLIXhc1ZZW5LwhuQtwUScUM2EZ8bIL3lUuW8zIOeI_0ubH0qPD8Y7KH1-38Vh0Kr84cljMZTe5HBhAEpnASZrg&user_id=1&vsn=2.0.0
```

#### Connection Parameters

```javascript
const params = {
  token: JWT,
  user_id: 1
  vsn: "2.0.0"
};
```

#### JavaScript Connection Example

```javascript
import { Socket } from "phoenix";

const socket = new Socket("ws://localhost:4000/socket", {
  params: {
    user_id: currentUserId,
    user_type: userType,
    vsn: "2.0.0",
  },
});

socket.connect();
```

### Available Channels

#### 1. Driver Available Channel

**Channel:** `driver:available`
**Purpose:** Broadcast new orders to available drivers

```javascript
// Join channel
const driverChannel = socket.channel("driver:available", {});
driverChannel
  .join()
  .receive("ok", (resp) => console.log("Joined driver channel", resp))
  .receive("error", (resp) => console.log("Unable to join", resp));

// Listen for new orders
driverChannel.on("new_order", (payload) => {
  console.log("New order received:", payload);
  // Handle new order notification
});
```

#### 2. Order Specific Channel

**Channel:** `order:{order_id}`
**Purpose:** Real-time updates for specific order

```javascript
// Join specific order channel
const orderChannel = socket.channel(`order:${orderId}`, {});
orderChannel
  .join()
  .receive("ok", (resp) => console.log("Joined order channel", resp))
  .receive("error", (resp) => console.log("Unable to join", resp));

// Listen for order updates
orderChannel.on("status_update", (payload) => {
  console.log("Order status updated:", payload);
});

orderChannel.on("location_update", (payload) => {
  console.log("Driver location updated:", payload);
});
```

### Message Format

WebSocket messages follow Phoenix Channel protocol:

```javascript
// Format: [join_ref, message_ref, topic, event, payload]
["1", "1", "driver:available", "phx_join", {}][
  ("1", "2", "order:123", "status_update", { status: "accepted" })
];
```

### Event Types

#### Driver Available Channel Events

- `new_order`: New order broadcast to drivers
- `order_cancelled`: Order cancellation notification

#### Order Channel Events

- `status_update`: Order status changes
- `location_update`: Real-time driver location
- `driver_assigned`: Driver acceptance notification
- `trip_started`: Trip initiation
- `trip_completed`: Trip completion

### WebSocket Event Payloads

#### New Order Event

```json
{
  "event": "new_order",
  "payload": {
    "order_id": "123e4567-e89b-12d3-a456-426614174000",
    "pickup_address": "Jl. Sudirman No. 1",
    "destination_address": "Mall Taman Anggrek",
    "distance_km": 5.2,
    "price": 25000,
    "customer": {
      "id": "456e7890-e89b-12d3-a456-426614174001",
      "name": "John Doe",
      "phone": "+6281234567890"
    }
  }
}
```

#### Location Update Event

```json
{
  "event": "location_update",
  "payload": {
    "driver_id": "789e0123-e89b-12d3-a456-426614174002",
    "latitude": -6.2,
    "longitude": 106.816666,
    "timestamp": "2025-01-15T10:30:00Z"
  }
}
```

## 🗄 Database Schema

### Users Table

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('customer', 'driver')),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  is_available BOOLEAN DEFAULT true,
  average_rating DECIMAL(3, 2) DEFAULT 0.0,
  total_ratings INTEGER DEFAULT 0,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### Orders Table

```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pickup_address TEXT NOT NULL,
  pickup_latitude DECIMAL(10, 8) NOT NULL,
  pickup_longitude DECIMAL(11, 8) NOT NULL,
  destination_address TEXT NOT NULL,
  destination_latitude DECIMAL(10, 8) NOT NULL,
  destination_longitude DECIMAL(11, 8) NOT NULL,
  distance_km DECIMAL(8, 2),
  price INTEGER NOT NULL,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')),
  customer_id UUID REFERENCES users(id),
  driver_id UUID REFERENCES users(id),
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### Ratings Table

```sql
CREATE TABLE ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  reviewer_type VARCHAR(20) NOT NULL CHECK (reviewer_type IN ('customer', 'driver')),
  order_id UUID REFERENCES orders(id),
  reviewer_id UUID REFERENCES users(id),
  reviewee_id UUID REFERENCES users(id),
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

## 🚀 Installation

### Prerequisites

- Elixir 1.18+ and Erlang/OTP 27
- PostgreSQL 12+
- Phoenix 1.8+
- Git

### Step-by-Step Installation

#### 1. Clone Repository

```bash
git clone https://github.com/DenkhulTech/denkhul_ojol.git
cd ojol_mvp
```

#### 2. Install Dependencies

```bash
mix deps.get
```

#### 3. Setup Database

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Optional: Seed data
mix run priv/repo/seeds.exs
```

#### 4. Start Development Server

```bash
mix phx.server
```

The application will be available at `http://localhost:4000`

## ⚙️ Configuration

### Database Configuration

Edit `config/dev.exs`:

```elixir
config :ojol_mvp, OjolMvp.Repo,
  username: "postgres",
  password: "your_password",
  hostname: "localhost",
  database: "ojol_mvp_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

### Production Configuration

Edit `config/prod.exs`:

```elixir
config :ojol_mvp, OjolMvp.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true
```

### Environment Variables

Create `.env` file:

```bash
DATABASE_URL=postgresql://username:password@localhost/ojol_mvp_prod
SECRET_KEY_BASE=your_secret_key_base_here
PHX_HOST=apijol.denkhultech.com
PORT=4000
```

## 🧪 Testing

### Run All Tests

```bash
mix test
```

### Run with Coverage

```bash
mix test --cover
```

### Run Specific Test Files

```bash
mix test test/ojol_mvp_web/controllers/user_controller_test.exs
```

### WebSocket Testing

Use WebSocket testing tools like:

- Browser Developer Console
- Postman WebSocket
- wscat CLI tool

Example with wscat:

```bash
wscat -c ws://localhost:4000/socket/websocket?user_id=123&user_type=driver&vsn=2.0.0
```

## 🚀 Deployment

### Production Deployment Status

#### ✅ Completed Features (90%)

- Database schema and migrations
- Complete CRUD API operations
- Custom ride-hailing endpoints
- Real-time WebSocket communication
- Order broadcasting system
- Location tracking functionality
- Rating and feedback system
- Basic error handling
- API documentation

#### 🚧 Production Enhancements Needed

- Authentication and authorization (JWT/OAuth)
- Advanced input validation and sanitization
- OpenStreetMap integration for routing
- Sophisticated distance calculation algorithms
- Enhanced driver matching with configurable radius
- Comprehensive error handling and logging
- Rate limiting and DDoS protection
- API versioning strategy
- Performance monitoring and metrics
- Automated testing pipeline
- Docker containerization
- Load balancing configuration

### Deployment Steps

#### 1. Build Release

```bash
mix deps.get --only prod
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release
```

#### 2. Database Migration

```bash
MIX_ENV=prod mix ecto.migrate
```

#### 3. Start Production Server

```bash
MIX_ENV=prod mix phx.server
```

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**

   ```bash
   git fork https://github.com/DenkhulTech/denkhul_ojol.git
   ```

2. **Create feature branch**

   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make your changes**

   ```bash
   # Write code
   # Add tests
   # Update documentation
   ```

4. **Run tests**

   ```bash
   mix test
   mix credo --strict
   mix format --check-formatted
   ```

5. **Commit changes**

   ```bash
   git commit -m 'feat: add amazing feature'
   ```

6. **Push to branch**

   ```bash
   git push origin feature/amazing-feature
   ```

7. **Create Pull Request**
   - Use clear, descriptive title
   - Include detailed description
   - Reference related issues
   - Add screenshots if applicable

### Code Standards

- Follow Elixir style guidelines
- Write comprehensive tests
- Update documentation
- Use conventional commit messages

## 📞 Support

- **Documentation**: [API Docs](https://apijol.denkhultech.com/docs/ui)
- **Issues**: [GitHub Issues](https://github.com/DenkhulTech/denkhul_ojol/issues)
- **Email**: support@denkhultech.com

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🌏 Bahasa Indonesia

### Gambaran Umum

OjolMVP adalah sistem backend komprehensif untuk aplikasi ride-hailing yang dibangun dengan Phoenix/Elixir. Sistem ini menyediakan manajemen pesanan real-time, pencocokan driver-customer yang cerdas, pelacakan GPS langsung, dan komunikasi dua arah melalui WebSocket channels.

### Fitur Utama

- **Operasi CRUD Lengkap** untuk pengguna, pesanan, dan rating
- **Komunikasi Real-time** via Phoenix Channels/WebSocket
- **Pelacakan GPS Langsung** dan update lokasi
- **Broadcast Pesanan** ke driver yang tersedia
- **Sistem Rating** untuk feedback kualitas layanan
- **Pencocokan Driver-Customer** dengan filter berbasis jarak
- **Manajemen Status Pesanan** dengan workflow lengkap

### Dokumentasi API

Dokumentasi interaktif tersedia di:
**[https://apijol.denkhultech.com/docs/ui](https://apijol.denkhultech.com/docs/ui)**

### Instalasi Cepat

```bash
# Clone repository
git clone https://github.com/DenkhulTech/denkhul_ojol.git
cd ojol_mvp

# Install dependencies
mix deps.get

# Setup database
mix ecto.create && mix ecto.migrate

# Jalankan server
mix phx.server
```

### Kontribusi

1. Fork repository ini
2. Buat branch fitur (`git checkout -b feature/fitur-menakjubkan`)
3. Commit perubahan (`git commit -m 'feat: tambah fitur menakjubkan'`)
4. Push ke branch (`git push origin feature/fitur-menakjubkan`)
5. Buat Pull Request

---

**Made with ❤️ by [DenkhulTech](https://denkhultech.com)**
