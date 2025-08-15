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

**서버 위치**: `/Users/kimsanghoon/Documents/GitHub/theway_server/`
**현재 상황**: 서버 재시작 시 문제 발생하여 실행이 안되는 상황

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
- Character: `/game/character/stats`, `/game/character/appearance`, `/game/character/cosmetics`
- Achievements: `/game/achievements`, `/game/achievements/progress`, `/game/achievements/:id/claim`
- Merchants: `/game/merchants/:id/dialogues`, `/game/merchants/:id/interact`, `/game/merchants/:id/relationship`

**Real-time Features** (Socket.IO):
- Price updates, nearby merchants, player locations
- Trade notifications, market alerts, system messages
- Location-based merchant discovery

### Network Architecture
- Base URL: `http://localhost:3000/api` (기본 포트)
- **포트 충돌 가능성**: 3000포트 사용중일 수 있음, 대안 포트 3001, 3002, 8000, 8080 고려 필요
- REST API with JWT authentication
- WebSocket connection for real-time features  
- Request caching and retry logic implemented
- Offline mode fallback with generated mock data

**Server Tech Stack**: Node.js, Express, Socket.IO, SQLite3, bcrypt, JWT
**Database**: SQLite with comprehensive game economy and progression systems

**주요 서버 파일들**:
- `src/server.js` - 메인 서버 엔트리 포인트
- `src/database/DatabaseManager.js` - 데이터베이스 연결 및 관리
- `src/routes/` - API 라우트 (auth.js, game.js)
- `src/services/` - 비즈니스 로직 (AuthService.js, GameService.js)
- `.env` - 환경 변수 설정 (PORT=3000, JWT_SECRET 등)

## Code Conventions

- Use Korean comments for domain-specific game logic
- Extensive use of `// MARK:` comments for code organization
- Published properties for SwiftUI state management
- Async/await for network operations
- Error handling with custom NetworkError enum
- Proper memory management with weak self references

## 현재 알려진 문제들

### 서버 재시작 문제
- **증상**: 서버가 처음에는 정상 작동하지만, 재시작할 때 실행이 안 됨
- **위치**: `/Users/kimsanghoon/Documents/GitHub/theway_server/`
- **실행 명령어**: `npm start` 또는 `node src/server.js`
- **가능한 원인**:
  1. 포트 3000이 이미 사용중일 가능성
  2. 데이터베이스 파일 권한 문제
  3. 환경 변수 설정 문제
  4. 중복 프로세스 실행

### 서버 재시작 방법 (권장)
```bash
# 1. 기존 프로세스 종료 후 재시작 (한 줄 명령어)
pkill -f "node src/server.js"; sleep 2; npm start

# 2. 단계별 재시작
ps aux | grep "node src/server.js" | grep -v grep  # 프로세스 확인
pkill -f "node src/server.js"                      # 서버 종료
npm start                                           # 서버 시작

# 3. 정상 작동 확인
curl http://localhost:3000/health                   # 헬스체크
```

### 디버깅 체크리스트
1. **포트 확인**: `lsof -i :3000`
2. **프로세스 종료**: `pkill -f "node src/server.js"` 또는 `lsof -ti:3000 | xargs kill -9`
3. **대안 포트 사용**: `.env` 파일에서 `PORT=3001` 등으로 변경
4. **로그 확인**: 서버 실행 시 콘솔 출력 메시지 확인
5. **권한 확인**: `data/` 폴더 및 SQLite DB 파일 읽기/쓰기 권한 확인

### iOS 앱의 서버 연결 설정
- iOS 앱에서는 `NetworkManager.swift:38`에서 `baseURL = "http://localhost:3000/api"` 설정
- `SocketManager.swift:52`에서 `serverURL = "http://localhost:3000"` 설정
- 서버 포트 변경 시 이 두 파일도 함께 수정 필요

### 협업을 위한 안전한 개발
- 코드 변경 시 항상 git status 확인 후 커밋
- 서버 코드 수정 전 백업 생성 권장
- 다른 개발자가 쉽게 이해할 수 있도록 명확한 주석과 문서화