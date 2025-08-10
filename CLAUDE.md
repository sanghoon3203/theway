# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS SwiftUI trading game called "Way" where players buy and sell items from various merchants across Seoul districts. The game features both offline and online modes with real-time multiplayer functionality.

## Development Commands

### Build and Run
- Build project: `xcodebuild -scheme way build`
- Run tests: `xcodebuild -scheme way test`
- Archive for release: `xcodebuild -scheme way archive`

### Available Schemes
- `way` - Main app target
- `MapboxMaps` - MapboxMaps dependency

### Build Configurations
- Debug - Development builds
- Release - Production builds

## Architecture

### Core Structure
The app follows MVVM architecture with SwiftUI and Combine:

- **App/**: Main app entry point and navigation
  - `wayApp.swift` - App entry point
  - `MainTabView.swift` - Main tab navigation
  - `ContentView.swift` - Root content view

- **Core/**: Core business logic managers
  - `GameManager.swift` - Main game state manager (ObservableObject)
  - `NetworkManager.swift` - HTTP API client with caching and retry logic
  - `SocketManager.swift` - WebSocket client for real-time features

- **Models/**: Data models with Codable conformance
  - Complex models like `Player`, `Merchant`, `TradeItem` with extensive properties
  - Enums for game states: `LicenseLevel`, `SeoulDistrict`, `ItemGrade`

- **Views/**: SwiftUI views organized by feature
  - Feature-based structure (Authentication/, Inventory/, Map/, etc.)
  - Components/ subdirectories for reusable UI components

### Key Patterns
- Publishers and Subscribers using Combine framework
- Core Location integration for location-based gameplay
- MapboxMaps integration for Seoul map display
- SocketIO for real-time multiplayer features

### Game Systems
- **Trading System**: Buy/sell items from merchants with dynamic pricing
- **Authentication**: Login/register with JWT tokens
- **Location-based**: Real-world Seoul locations mapped to game districts
- **License System**: Player progression through different license levels
- **Real-time Features**: Live price updates, nearby players, merchant availability

### Dependencies
- MapboxMaps (11.13.4) - Map functionality
- SocketIO (16.1.1) - Real-time communication
- Starscream (4.0.8) - WebSocket support
- Turf (4.0.0) - Geographic calculations

### Server Integration (theway_server)

**Database Schema**: Comprehensive SQLite database with 30+ tables covering:
- User authentication and player data
- Character progression system (levels, stats, skills, cosmetics)
- Complex item system (modern + fantasy items with rarity, enhancement, enchantments)
- Advanced merchant system (personalities, dialogues, relationships, mood events)
- Trading system (negotiations, market trends, auctions, contracts)
- Guild system and insurance mechanics

**API Endpoints**:
- Authentication: `/auth/register`, `/auth/login`, `/auth/refresh`
- Game data: `/game/player/data`, `/game/market/prices`, `/game/merchants`
- Trading: `/game/trade/buy`, `/game/trade/sell`, `/game/trade/history`

**Real-time Features** (Socket.IO):
- Price updates, nearby merchants, player locations
- Trade notifications, market alerts, system messages
- Location-based merchant discovery

### Network Architecture
- Base URL: `http://localhost:3000/api`
- REST API with JWT authentication
- WebSocket connection for real-time features
- Request caching and retry logic implemented
- Offline mode fallback with generated mock data

**Server Tech Stack**: Node.js, Express, Socket.IO, SQLite3, bcrypt, JWT
**Database**: SQLite with comprehensive game economy and progression systems

## Code Conventions

- Use Korean comments for domain-specific game logic
- Extensive use of `// MARK:` comments for code organization
- Published properties for SwiftUI state management
- Async/await for network operations
- Error handling with custom NetworkError enum
- Proper memory management with weak self references