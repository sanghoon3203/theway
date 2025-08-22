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

---

# 🎮 게임 UI/UX 개선 로드맵 (20년차 게임개발자 모드)

## 개발 철학
- **직관적 코딩**: 변수명/함수명은 의도가 명확히 드러나도록 작성
- **모듈화**: 각 기능은 독립적으로 테스트 가능하도록 분리
- **확장성**: 새로운 지역/상점 추가가 용이한 구조
- **성능 최적화**: 메모리 누수 방지, 비동기 처리 적극 활용

## 📋 현재 진행 상황 체크리스트

### ✅ 완료된 작업
- [x] 회원가입/로그인 시스템 정상 작동
- [x] GameManager environmentObject 의존성 해결
- [x] Socket 연결 안정화 (127.0.0.1:3001)
- [x] 메인 맵뷰에서 PlayerStatusBar, QuickInfoPanel 제거
- [x] 기존 데이터베이스 스키마 분석 완료

### 🔄 진행 중인 작업
- [ ] 서울 지역별 특화 상점 시스템 설계

### 📅 다음 단계 작업 목록

## 1️⃣ 우선순위 1: 지역별 특화 상점 시스템 (2-3주)

### 기존 DB 활용 방식
```sql
-- 기존 merchants 테이블 활용
-- district: "서촌", "강남", "종로", "홍대", "명동", "이태원"
-- type: "베이커리", "의료용품", "고물상", "악기상", "화장품", "수입식품"
-- preferred_items: JSON 형태로 지역 특화 아이템 목록

-- 기존 item_master 테이블 활용  
-- category/subcategory: 지역별 특화 상품 분류
-- rarity: 지역별 희귀도 조정
-- base_price: 지역별 가격 차등화
```

### 구현 상세 계획

#### A. 서버 사이드 개선
**파일**: `src/services/GameService.js`
```javascript
// 지역별 상점 필터링 함수 (직관적 명명)
async getDistrictSpecialtyShops(district, playerLevel) {
  // 명명 규칙: get + 대상 + 조건
}

// 지역별 아이템 가격 조정 함수
calculateDistrictPriceModifier(item, district, merchantType) {
  // 명명 규칙: calculate + 계산대상 + 조건
}
```

**파일**: `src/database/seeds/DistrictData.js` (신규 생성)
```javascript
// 지역별 상점 데이터 시드
const DISTRICT_SHOP_CONFIG = {
  "서촌": {
    specialties: ["베이커리", "독립서점", "갤러리카페"],
    priceModifiers: { "식품": 1.2, "문화용품": 1.1 },
    demographics: "젊은층_문화인"
  }
  // ... 다른 지역들
}
```

#### B. iOS 클라이언트 개선
**파일**: `way/Models/District.swift` (신규 생성)
```swift
// 직관적 모델 설계
struct SeoulDistrict: Identifiable, Codable {
    let id: String
    let nameKorean: String    // "서촌"
    let nameEnglish: String   // "Seochon"
    let specialtyTypes: [ShopSpecialtyType]
    let culturalTheme: DistrictTheme
    let priceLevel: PriceLevel  // 1(저렴) ~ 5(고급)
}

enum ShopSpecialtyType: String, CaseIterable {
    case bakery = "베이커리"
    case medicalSupplies = "의료용품"
    case antiques = "고물상"
    // 확장 용이성을 위한 enum 설계
}
```

**파일**: `way/Views/Map/Components/DistrictAwareMapView.swift` (신규)
```swift
// 지역별 특화 마커 표시
struct DistrictSpecialtyMarker: View {
    let merchant: Merchant
    let districtTheme: DistrictTheme
    
    var specialtyIcon: String {
        // 지역+상점타입에 따른 아이콘 자동 선택
        return IconMapper.getSpecialtyIcon(
            district: merchant.district,
            shopType: merchant.type
        )
    }
}
```

## 2️⃣ 우선순위 2: Mapbox 3D 지도 개선 (3-4주)

### Mapbox Style Specification 활용
**참고 문서**: https://docs.mapbox.com/style-spec/reference/

#### A. 3D 빌딩 레이어 구현
**파일**: `way/Views/Map/Styles/SeoulBuildingStyle.swift` (신규)
```swift
// 서울 주요 건물 3D 렌더링
class SeoulBuildingStyleManager {
    
    // 직관적 함수명: 동작 + 대상 + 조건
    func enableBuildingExtrusionForDistrict(_ district: SeoulDistrict) {
        // 지역별 건물 높이 데이터 적용
    }
    
    func customizeBuildingColorByUsage(_ usage: BuildingUsage) {
        // 용도별 건물 색상 차별화 (상업/주거/문화시설)
    }
}
```

#### B. 커스텀 마커 시스템
**파일**: `way/Views/Map/Components/DistrictMarkerFactory.swift` (신규)
```swift
// Factory 패턴으로 확장성 확보
class DistrictMarkerFactory {
    
    static func createMarkerForMerchant(
        _ merchant: Merchant,
        in district: SeoulDistrict
    ) -> AnyView {
        // 지역별 특화 마커 생성
        // 예: 서촌 베이커리 = 크루아상 모양 마커
    }
    
    // 마커 애니메이션 효과
    static func animateMarkerAppearance(
        delay: TimeInterval = 0
    ) -> Animation {
        // 부드러운 등장 애니메이션
    }
}
```

## 3️⃣ 우선순위 3: 캐릭터 시스템 활용 (2-3주)

### 기존 DB 테이블 활용
```sql
-- character_stats: 스탯 시각화
-- character_appearance: 아바타 커스터마이징  
-- character_cosmetics: 착용 아이템
```

#### A. 스탯 시각화 UI
**파일**: `way/Views/Character/Components/StatsRadarChart.swift` (신규)
```swift
// 직관적인 스탯 표시
struct PlayerStatsRadarChart: View {
    let stats: CharacterStats
    
    // 명확한 프로퍼티명
    var negotiationSkillPercentage: Double {
        return Double(stats.negotiation_skill) / 100.0
    }
    
    var tradingEfficiencyLevel: Int {
        return stats.trading_skill
    }
}
```

#### B. 착용 아이템 UI
**파일**: `way/Views/Character/Equipment/EquipmentSlotView.swift` (신규)
```swift
// MMO 스타일 장비창
struct EquipmentInventoryGrid: View {
    @State private var equippedItems: [EquipmentSlot: CosmeticItem] = [:]
    
    // 드래그 앤 드롭 지원
    func handleItemEquip(item: CosmeticItem, to slot: EquipmentSlot) {
        // 직관적 함수명으로 의도 명확화
    }
}

enum EquipmentSlot: String, CaseIterable {
    case outfit = "상의"
    case accessory = "액세서리"  
    case hairStyle = "헤어스타일"
    // 확장 가능한 enum 설계
}
```

## 4️⃣ 우선순위 4: 상점 UI 혁신 (3-4주)

#### A. 3D 상점 인터페이스
**파일**: `way/Views/Shop/3D/Shop3DInteriorView.swift` (신규)
```swift
// SceneKit 활용 3D 상점 내부
struct Shop3DInteriorView: UIViewRepresentable {
    let shopType: ShopSpecialtyType
    let inventory: [TradeItem]
    
    // 상점 타입별 3D 모델 로딩
    func loadShopModel(for type: ShopSpecialtyType) -> SCNScene? {
        // 베이커리 = 빵 진열대, 의료용품점 = 약품 진열장
    }
}
```

#### B. 협상 시스템 UI  
**파일**: `way/Views/Shop/Negotiation/NegotiationCardGame.swift` (신규)
```swift
// 포커 스타일 가격 협상
struct PriceNegotiationGame: View {
    let merchant: Merchant
    let item: TradeItem
    @State private var playerCards: [NegotiationCard] = []
    @State private var merchantConfidence: Double = 0.5
    
    // 스탯 기반 협상 성공률 계산
    func calculateNegotiationSuccessRate() -> Double {
        // 캐릭터 스탯 반영한 확률 계산
    }
}
```

## 📊 개발 진행 체크포인트

### Week 1-2: 지역별 상점 데이터 구축
- [ ] 서울 6개 주요 지역 상점 데이터 입력
- [ ] 지역별 가격 조정 로직 구현
- [ ] 상점 타입별 아이콘 에셋 준비

### Week 3-4: Mapbox 3D 맵 구현  
- [ ] 3D 빌딩 레이어 활성화
- [ ] 지역별 커스텀 마커 적용
- [ ] 부드러운 마커 애니메이션 구현

### Week 5-6: 캐릭터 시스템 UI
- [ ] 스탯 레이더 차트 구현
- [ ] 착용 아이템 장비창 UI
- [ ] 캐릭터 아바타 실시간 반영

### Week 7-8: 상점 인터페이스 혁신
- [ ] 3D 상점 내부 뷰 프로토타입
- [ ] 협상 카드 게임 기본 로직
- [ ] 상점별 특화 인터랙션

## 🛠 개발 시 준수사항

### 코딩 컨벤션
```swift
// ✅ 좋은 예시 - 직관적 명명
func calculateOptimalTradingRoute(from source: District, to destination: District) -> TradingRoute?

// ❌ 나쁜 예시 - 불분명한 명명  
func calc(s: String, d: String) -> Any?

// ✅ 좋은 예시 - 의도가 명확한 변수명
private var isNegotiationInProgress: Bool = false
private var currentMerchantMoodLevel: MerchantMood = .neutral

// ❌ 나쁜 예시 - 약어나 불분명한 명명
private var isNegotiating: Bool = false
private var mood: Int = 0
```

### 에러 처리
```swift
// 상세한 에러 타입 정의로 디버깅 용이성 확보
enum ShopInteractionError: LocalizedError {
    case insufficientFunds(required: Int, available: Int)
    case inventoryFull(currentCount: Int, maxCapacity: Int)
    case merchantUnavailable(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .insufficientFunds(let required, let available):
            return "자금 부족: 필요 \(required)원, 보유 \(available)원"
        // ... 다른 케이스들
        }
    }
}
```

### 성능 최적화 가이드라인
```swift
// 메모리 누수 방지
class ShopViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        // 명시적 정리로 메모리 누수 방지
        cancellables.removeAll()
    }
}

// 비동기 작업 최적화
@MainActor
func updateShopInventoryDisplay() async {
    // UI 업데이트는 메인 스레드에서
}
```

## 🎯 최종 목표
- **몰입감**: 실제 서울 거리를 걷는 듯한 경험
- **개성**: 각 지역별 고유한 매력과 특색
- **성장감**: 캐릭터 발전이 게임플레이에 실질적 영향  
- **사회성**: 지역별 상인들과의 관계 형성

## 📝 주의사항
- 각 기능 구현 후 반드시 단위 테스트 작성
- UI 변경 시 접근성(Accessibility) 고려
- 서버 API 변경 시 iOS 클라이언트와 동기화 확인
- Git 커밋 메시지는 기능 단위로 명확하게 작성