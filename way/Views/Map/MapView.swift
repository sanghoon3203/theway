// 📁 Views/Map/MapView.swift - 단순화된 버전
import SwiftUI
import MapboxMaps
import CoreLocation

struct MapView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var viewport: Viewport = .camera(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        zoom: 12
    )
    @State private var showingMerchantSheet = false
    @State private var selectedMerchant: Merchant?
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var showsBearingImage = false
    @State private var isTracking = true
    
    var body: some View {
        ZStack {
            // 맵박스 지도 - 단순화된 버전
            Map(viewport: $viewport) {
                // 사용자 위치 표시
                Puck2D(bearing: showsBearingImage ? .heading : .course)
                
                // 상인들 마커 - 직접 나열 방식 (최대 10명)
                if gameManager.merchants.count > 0 {
                    MapViewAnnotation(coordinate: gameManager.merchants[0].coordinate) {
                        MerchantMarkerSimple(
                            merchant: gameManager.merchants[0],
                            number: 1
                        ) {
                            selectedMerchant = gameManager.merchants[0]
                            showingMerchantSheet = true
                        }
                    }
                }
                
                if gameManager.merchants.count > 1 {
                    MapViewAnnotation(coordinate: gameManager.merchants[1].coordinate) {
                        MerchantMarkerSimple(
                            merchant: gameManager.merchants[1],
                            number: 2
                        ) {
                            selectedMerchant = gameManager.merchants[1]
                            showingMerchantSheet = true
                        }
                    }
                }
                
                if gameManager.merchants.count > 2 {
                    MapViewAnnotation(coordinate: gameManager.merchants[2].coordinate) {
                        MerchantMarkerSimple(
                            merchant: gameManager.merchants[2],
                            number: 3
                        ) {
                            selectedMerchant = gameManager.merchants[2]
                            showingMerchantSheet = true
                        }
                    }
                }
                
                if gameManager.merchants.count > 3 {
                    MapViewAnnotation(coordinate: gameManager.merchants[3].coordinate) {
                        MerchantMarkerSimple(
                            merchant: gameManager.merchants[3],
                            number: 4
                        ) {
                            selectedMerchant = gameManager.merchants[3]
                            showingMerchantSheet = true
                        }
                    }
                }
                
                if gameManager.merchants.count > 4 {
                    MapViewAnnotation(coordinate: gameManager.merchants[4].coordinate) {
                        MerchantMarkerSimple(
                            merchant: gameManager.merchants[4],
                            number: 5
                        ) {
                            selectedMerchant = gameManager.merchants[4]
                            showingMerchantSheet = true
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .onMapTapGesture { _ in
                stopTracking()
            }
            .ignoresSafeArea()
            
            // UI 오버레이
            VStack {
                // 상단 플레이어 상태바
                PlayerStatusBar()
                    .environmentObject(gameManager)
                
                Spacer()
                
                // 하단 빠른 정보 패널
                QuickInfoPanel()
                    .environmentObject(gameManager)
                
                // 위치 추적 버튼
                HStack {
                    Spacer()
                    LocationTrackingButton(isTracking: $isTracking, viewport: $viewport)
                        .padding(.trailing, 20)
                        .padding(.bottom, 10)
                }
            }
            .padding()
        }
        .sheet(item: $selectedMerchant) { merchant in
            MerchantDetailSheet(merchant: merchant)
                .environmentObject(gameManager)
        }
    }
    
    private func stopTracking() {
        isTracking = false
        viewport = .idle
    }
}
