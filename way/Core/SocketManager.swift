//
//  SocketManager.swift
//  way
//
//  Created by 김상훈 on 7/29/25.
//


// 📁 Core/SocketManager.swift
import Foundation
import SocketIO

class SocketManager: ObservableObject {
    static let shared = SocketManager()
    
    private var manager: SocketIO.SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    @Published var nearbyMerchants: [Merchant] = []
    @Published var priceUpdates: [String: Int] = [:]
    
    private init() {}
    
    func connect() {
        let url = URL(string: "http://localhost:3000")!
        manager = SocketIO.SocketManager(socketURL: url, config: [
            .log(true),
            .compress,
            .reconnects(true),
            .reconnectWait(3)
        ])
        
        socket = manager?.defaultSocket
        
        // 이벤트 리스너 설정
        socket?.on(clientEvent: .connect) { data, ack in
            print("Socket 연결됨")
            self.isConnected = true
        }
        
        socket?.on("welcome") { data, ack in
            if let welcome = data[0] as? [String: Any] {
                print("서버 환영 메시지: \(welcome)")
            }
        }
        
        socket?.on("priceUpdate") { data, ack in
            // 실시간 가격 업데이트
            if let updates = data[0] as? [String: Int] {
                DispatchQueue.main.async {
                    self.priceUpdates = updates
                }
            }
        }
        
        socket?.on("nearbyMerchants") { data, ack in
            // 주변 상인 업데이트
            if let merchantData = data[0] as? [[String: Any]] {
                // 파싱 로직
            }
        }
        
        socket?.on(clientEvent: .disconnect) { data, ack in
            print("Socket 연결 해제")
            self.isConnected = false
        }
        
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
    }
    
    func sendLocation(latitude: Double, longitude: Double) {
        socket?.emit("updateLocation", [
            "lat": latitude,
            "lng": longitude
        ])
    }
    
    func joinRoom(_ roomId: String) {
        socket?.emit("joinRoom", roomId)
    }
}
