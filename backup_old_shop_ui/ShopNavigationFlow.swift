// 📁 Views/Shop/ShopNavigationFlow.swift - 새로운 상점 네비게이션 시스템
import SwiftUI

struct ShopNavigationFlow: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var selectedNavigationMode: NavigationMode = .districtMap
    
    enum NavigationMode {
        case districtMap    // 지역별 상점 탐색
        case nearbyShops    // 주변 상점 (현재 위치 기반)
        case favorites      // 즐겨찾는 상점
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 상단 네비게이션 모드 선택
                shopNavigationSelector
                
                // 선택된 모드에 따른 콘텐츠
                Group {
                    switch selectedNavigationMode {
                    case .districtMap:
                        SeoulDistrictMapView()
                    case .nearbyShops:
                        NearbyShopsView()
                    case .favorites:
                        FavoriteShopsView()
                    }
                }
                .environmentObject(gameManager)
            }
            .navigationTitle("서울 상점가")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - 네비게이션 선택기
    private var shopNavigationSelector: some View {
        HStack(spacing: 0) {
            ForEach([
                (NavigationMode.districtMap, "map.fill", "지역별"),
                (NavigationMode.nearbyShops, "location.fill", "주변 상점"),
                (NavigationMode.favorites, "heart.fill", "즐겨찾기")
            ], id: \.0) { mode, icon, title in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedNavigationMode = mode
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                        
                        Text(title)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedNavigationMode == mode ? .brushText : .fadeText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedNavigationMode == mode ? Color.inkMist.opacity(0.2) : Color.clear)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.softWhite.opacity(0.95))
    }
}

// MARK: - 임시 플레이스홀더 뷰들 (향후 구현)
struct SeoulDistrictMapView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(SeoulDistrict.allDistricts, id: \.id) { district in
                    DistrictCard(district: district)
                }
            }
            .padding()
        }
    }
}

struct NearbyShopsView: View {
    var body: some View {
        VStack {
            Image(systemName: "location.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.fadeText)
            
            Text("주변 상점 검색")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.brushText)
            
            Text("현재 위치 기반으로 주변 상점을 찾아보세요")
                .font(.caption)
                .foregroundColor(.fadeText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.softWhite.opacity(0.3))
    }
}

struct FavoriteShopsView: View {
    var body: some View {
        VStack {
            Image(systemName: "heart.slash")
                .font(.system(size: 50))
                .foregroundColor(.fadeText)
            
            Text("즐겨찾는 상점이 없습니다")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.brushText)
            
            Text("자주 방문하는 상점을 즐겨찾기에 추가해보세요")
                .font(.caption)
                .foregroundColor(.fadeText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.softWhite.opacity(0.3))
    }
}

// MARK: - 지역 데이터 모델
struct SeoulDistrict: Identifiable {
    let id: String
    let nameKorean: String
    let nameEnglish: String
    let specialtyTypes: [String]
    let description: String
    let colorTheme: Color
    let icon: String
    
    static let allDistricts = [
        SeoulDistrict(
            id: "seochon",
            nameKorean: "서촌",
            nameEnglish: "Seochon",
            specialtyTypes: ["베이커리", "독립서점", "갤러리카페"],
            description: "젊은 문화인들이 모이는 감성 거리",
            colorTheme: Color(hex: "#8B4513"),
            icon: "book.fill"
        ),
        SeoulDistrict(
            id: "gangnam",
            nameKorean: "강남",
            nameEnglish: "Gangnam",
            specialtyTypes: ["의료용품", "외국어서적", "정장점"],
            description: "비즈니스와 교육의 중심지",
            colorTheme: Color(hex: "#4169E1"),
            icon: "building.2.fill"
        ),
        SeoulDistrict(
            id: "jongno",
            nameKorean: "종로",
            nameEnglish: "Jongno",
            specialtyTypes: ["고물상", "고철상", "전통약재"],
            description: "역사와 전통이 살아있는 거리",
            colorTheme: Color(hex: "#8B6914"),
            icon: "archivebox.fill"
        ),
        SeoulDistrict(
            id: "hongdae",
            nameKorean: "홍대",
            nameEnglish: "Hongdae",
            specialtyTypes: ["악기상", "미술용품", "의류편집샵"],
            description: "문화와 예술의 거리",
            colorTheme: Color(hex: "#8A2BE2"),
            icon: "music.note"
        ),
        SeoulDistrict(
            id: "myeongdong",
            nameKorean: "명동",
            nameEnglish: "Myeongdong",
            specialtyTypes: ["화장품", "기념품", "면세품"],
            description: "관광과 쇼핑의 메카",
            colorTheme: Color(hex: "#FF69B4"),
            icon: "bag.fill"
        ),
        SeoulDistrict(
            id: "itaewon",
            nameKorean: "이태원",
            nameEnglish: "Itaewon",
            specialtyTypes: ["수입식품", "외국서적", "에스닉용품"],
            description: "국제적 다문화 지역",
            colorTheme: Color(hex: "#20B2AA"),
            icon: "globe"
        )
    ]
}

// MARK: - 지역 카드 컴포넌트
struct DistrictCard: View {
    let district: SeoulDistrict
    
    var body: some View {
        NavigationLink(destination: DistrictDetailView(district: district)) {
            VStack(alignment: .leading, spacing: 12) {
                // 아이콘과 지역명
                HStack {
                    Image(systemName: district.icon)
                        .font(.title2)
                        .foregroundColor(district.colorTheme)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(district.nameKorean)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.brushText)
                        
                        Text(district.nameEnglish)
                            .font(.caption)
                            .foregroundColor(.fadeText)
                    }
                    
                    Spacer()
                }
                
                // 설명
                Text(district.description)
                    .font(.caption)
                    .foregroundColor(.fadeText)
                    .lineLimit(2)
                
                // 특화 상품 태그
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 4) {
                    ForEach(district.specialtyTypes.prefix(4), id: \.self) { specialty in
                        Text(specialty)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(district.colorTheme.opacity(0.2))
                            .foregroundColor(district.colorTheme)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.softWhite)
                    .shadow(color: Color.inkMist.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 지역 상세 뷰 (임시)
struct DistrictDetailView: View {
    let district: SeoulDistrict
    
    var body: some View {
        VStack {
            Text("\(district.nameKorean) 상점가")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(district.colorTheme)
            
            Text("곧 다양한 상점들을 만나보실 수 있습니다!")
                .font(.title3)
                .foregroundColor(.fadeText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(district.colorTheme.opacity(0.1))
        .navigationTitle(district.nameKorean)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ShopNavigationFlow()
        .environmentObject(GameManager())
}