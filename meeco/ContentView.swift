//
//  ContentView.swift
//  meeco
//

import Foundation
import SwiftUI
import AVKit
import WebKit
import ImageIO

struct ContentView: View {
    @State private var selectedTab: MeecoAppTab = .main
    @State private var webAction: MeecoWebAction?
    @StateObject private var authSession = MeecoAuthSession()
    @StateObject private var notificationCenter = NotificationCenterViewModel()
    @AppStorage("favoriteBoardIDs") private var favoriteBoardIDsStorage = ""

    var body: some View {
        NavigationView {
            BoardDirectoryView(
                sections: selectedTab.sections(favoriteBoardIDs: favoriteBoardIDsStorage.boardIDSet),
                title: selectedTab.title,
                selectedTab: $selectedTab,
                onSearch: openRootSearch
            )
        }
        .environmentObject(authSession)
        .environmentObject(notificationCenter)
        .sheet(item: $webAction) { action in
            WebActionView(action: action)
        }
        .task {
            await authSession.verifySession()
            if authSession.isLoggedIn {
                await notificationCenter.load()
            }
        }
    }

    private func openRootSearch() {
        webAction = MeecoWebAction(title: "검색", url: MeecoBoard.all.searchURL(query: "", category: nil))
    }
}

enum MeecoAppTab: String, CaseIterable, Identifiable {
    case main
    case board
    case favorite
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .main: return "Main"
        case .board: return "Board"
        case .favorite: return "Favorite"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .main: return "house"
        case .board: return "list.bullet.rectangle"
        case .favorite: return "star"
        case .settings: return "gearshape"
        }
    }

    func sections(favoriteBoardIDs: Set<String>) -> [MeecoDirectorySection] {
        switch self {
        case .main:
            return MeecoDirectorySection.mainSections(favoriteBoardIDs: favoriteBoardIDs)
        case .board:
            return MeecoDirectorySection.boardSections
        case .favorite:
            return MeecoDirectorySection.favoriteSections(favoriteBoardIDs: favoriteBoardIDs)
        case .settings:
            return MeecoDirectorySection.settingsSections
        }
    }
}

struct BoardDirectoryView: View {
    let sections: [MeecoDirectorySection]
    let title: String
    @Binding var selectedTab: MeecoAppTab
    let onSearch: () -> Void
    @EnvironmentObject private var notificationCenter: NotificationCenterViewModel

    var body: some View {
        Group {
            if sections.isEmpty {
                FavoriteEmptyState()
            } else {
                List {
                    ForEach(sections) { section in
                        Section(section.title) {
                            ForEach(section.items) { item in
                                switch item.destination {
                                case .board(let board):
                                    NavigationLink(destination: BoardView(board: board).hideRootTabBar()) {
                                        DirectoryItemRow(item: item)
                                    }
                                case .web(let action):
                                    NavigationLink(destination: WebActionView(action: action).hideRootTabBar()) {
                                        DirectoryItemRow(item: item)
                                    }
                                case .account:
                                    NavigationLink(destination: AccountSettingsView().hideRootTabBar()) {
                                        DirectoryItemRow(item: item)
                                    }
                                case .attendance:
                                    NavigationLink(destination: AttendanceView().hideRootTabBar()) {
                                        DirectoryItemRow(item: item)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: NotificationCenterView().hideRootTabBar()) {
                    NotificationToolbarIcon(unreadCount: notificationCenter.unreadCount)
                }
                .accessibilityLabel("알림")
            }
        }
        .showRootTabBar()
        .safeAreaInset(edge: .bottom) {
            RootNavigationBar(selectedTab: $selectedTab, onSearch: onSearch)
        }
    }
}

struct NotificationToolbarIcon: View {
    let unreadCount: Int

    var body: some View {
        Image(systemName: unreadCount > 0 ? "bell.badge" : "bell")
            .symbolRenderingMode(unreadCount > 0 ? .palette : .monochrome)
            .foregroundStyle(unreadCount > 0 ? Color.accentColor : Color.primary, Color.red)
    }
}

struct RootNavigationBar: View {
    @Binding var selectedTab: MeecoAppTab
    let onSearch: () -> Void

    var body: some View {
        BottomControlBackdrop {
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(MeecoAppTab.allCases) { tab in
                        Button {
                            selectedTab = tab
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: tab.systemImage)
                                    .font(.title3.weight(selectedTab == tab ? .bold : .semibold))
                                Text(tab.title)
                                    .font(.caption.weight(selectedTab == tab ? .bold : .semibold))
                            }
                            .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(tab.title)
                    }
                }
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .boardLiquidGlass(cornerRadius: 32)

                Button(action: onSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 66, height: 66)
                .rootProminentLiquidGlassButton()
                .shadow(color: Color.accentColor.opacity(0.28), radius: 16, y: 6)
                .accessibilityLabel("검색")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
    }
}

struct BottomControlBackdrop<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(alignment: .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black.opacity(0.45), location: 0.28),
                                .init(color: .black.opacity(0.88), location: 0.58),
                                .init(color: .black, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea(edges: .bottom)
            }
            .contentShape(Rectangle())
    }
}

struct FavoriteEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "star")
                .font(.largeTitle.weight(.semibold))
                .foregroundColor(.secondary)
            Text("즐겨찾기 없음")
                .font(.headline)
            Text("게시판 화면의 별 버튼으로 자주 보는 게시판을 추가할 수 있습니다.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 88)
    }
}

struct DirectoryItemRow: View {
    let item: MeecoDirectoryItem

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        } icon: {
            Image(systemName: item.systemImage)
                .foregroundColor(.accentColor)
        }
        .padding(.vertical, 4)
    }
}

struct MeecoDirectorySection: Identifiable {
    let id: String
    let title: String
    let items: [MeecoDirectoryItem]

    static func mainSections(favoriteBoardIDs: Set<String>) -> [MeecoDirectorySection] {
        let favoriteItems = MeecoBoard.boards(matching: favoriteBoardIDs).map(MeecoDirectoryItem.board)
        let favorites = favoriteItems.isEmpty ? [] : [
            MeecoDirectorySection(id: "favorites", title: "즐겨찾기", items: favoriteItems)
        ]

        return favorites + [
            MeecoDirectorySection(id: "main", title: "메인", items: [
            .board(.all),
            .board(.monthly),
            .board(.makgora),
            .web(id: "watchAds", title: "광고 보기", description: "미코 광고 보기", systemImage: "play.rectangle", url: URL(string: "https://meeco.kr/Support/38683562")!),
            .web(id: "sendDonation", title: "도네 쏘기", description: "미코 후원 보내기", systemImage: "paperplane.fill", url: URL(string: "https://meeco.kr/Support/39348818")!),
            .board(.balloon)
            ])
        ]
    }

    static func favoriteSections(favoriteBoardIDs: Set<String>) -> [MeecoDirectorySection] {
        let favoriteItems = MeecoBoard.boards(matching: favoriteBoardIDs).map(MeecoDirectoryItem.board)
        guard !favoriteItems.isEmpty else { return [] }
        return [
            MeecoDirectorySection(id: "favorites", title: "즐겨찾기", items: favoriteItems)
        ]
    }

    static let boardSections: [MeecoDirectorySection] = [
        MeecoDirectorySection(id: "hot", title: "HOT 게시물", items: [.board(.hot)]),
        MeecoDirectorySection(id: "it", title: "IT+", items: [.board(.news), .board(.mini), .board(.review), .board(.big), .board(.ai)]),
        MeecoDirectorySection(id: "community", title: "자유+", items: [.board(.free), .board(.humor), .board(.gallery), .board(.anonymous)]),
        MeecoDirectorySection(id: "price", title: "가격+", items: [.board(.price), .board(.purchase), .board(.market), .board(.enterprise)])
    ]

    static let settingsSections: [MeecoDirectorySection] = [
        MeecoDirectorySection(id: "account", title: "계정", items: [
            .account,
            .attendance,
            .web(id: "sticker", title: "스티커 상점", description: "스티커 구매 및 관리", systemImage: "face.smiling", url: URL(string: "https://meeco.kr/sticker")!)
        ]),
        MeecoDirectorySection(id: "participation", title: "참여 / 운영", items: [
            .board(.event),
            .board(.bugUpdate),
            .board(.notice)
        ])
    ]
}

struct MeecoDirectoryItem: Identifiable {
    enum Destination {
        case board(MeecoBoard)
        case web(MeecoWebAction)
        case account
        case attendance
    }

    let id: String
    let title: String
    let description: String
    let systemImage: String
    let destination: Destination

    static func board(_ board: MeecoBoard) -> MeecoDirectoryItem {
        MeecoDirectoryItem(
            id: board.id,
            title: board.title,
            description: board.description,
            systemImage: board.systemImage,
            destination: .board(board)
        )
    }

    static func web(id: String, title: String, description: String, systemImage: String, url: URL) -> MeecoDirectoryItem {
        MeecoDirectoryItem(
            id: id,
            title: title,
            description: description,
            systemImage: systemImage,
            destination: .web(MeecoWebAction(title: title, url: url))
        )
    }

    static let account = MeecoDirectoryItem(
        id: "login",
        title: "로그인",
        description: "미코 계정 로그인",
        systemImage: "person.crop.circle",
        destination: .account
    )

    static let attendance = MeecoDirectoryItem(
        id: "attendance",
        title: "출석부",
        description: "오늘 출석 상태와 최근 출석 기록",
        systemImage: "calendar.badge.checkmark",
        destination: .attendance
    )
}

struct MeecoBoard: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let systemImage: String
    let url: URL
    let allowedBoardPaths: Set<String>?
    var categories: [MeecoBoardCategory] = []

    var showsSourceBoardBadges: Bool {
        (allowedBoardPaths?.count ?? 0) > 1
    }

    static let articleBoardPaths: Set<String> = [
        "Hot",
        "All",
        "Monthly",
        "Makgora",
        "Balloon",
        "news",
        "mini",
        "Review",
        "big",
        "AI",
        "free",
        "humor",
        "Gallery",
        "anonymous",
        "Price",
        "Purchase",
        "market",
        "Enterprise",
        "Event",
        "BugUpdate",
        "notice"
    ]

    static let all = MeecoBoard(
        id: "all",
        title: "모아보기",
        description: "미코 전체 게시물 모아보기",
        systemImage: "rectangle.grid.1x2.fill",
        url: URL(string: "https://meeco.kr/All")!,
        allowedBoardPaths: articleBoardPaths
    )

    static let monthly = MeecoBoard(
        id: "monthly",
        title: "월간 미코",
        description: "월간 인기 게시물",
        systemImage: "calendar",
        url: URL(string: "https://meeco.kr/Monthly")!,
        allowedBoardPaths: articleBoardPaths
    )

    static let makgora = MeecoBoard(
        id: "makgora",
        title: "막고라",
        description: "막고라 게시판",
        systemImage: "bolt.fill",
        url: URL(string: "https://meeco.kr/Makgora")!,
        allowedBoardPaths: ["Makgora"]
    )

    static let balloon = MeecoBoard(
        id: "balloon",
        title: "미코 도네",
        description: "미코 후원 내역",
        systemImage: "gift.fill",
        url: URL(string: "https://meeco.kr/Balloon")!,
        allowedBoardPaths: ["Balloon"]
    )

    static let hot = MeecoBoard(
        id: "hot",
        title: "HOT 게시물",
        description: "미코 전체 인기 게시물",
        systemImage: "flame.fill",
        url: URL(string: "https://meeco.kr/Hot")!,
        allowedBoardPaths: articleBoardPaths
    )

    static let news = MeecoBoard(
        id: "news",
        title: "IT 소식",
        description: "최신 IT 뉴스와 회원 소식",
        systemImage: "newspaper.fill",
        url: URL(string: "https://meeco.kr/news")!,
        allowedBoardPaths: ["news"]
    )

    static let mini = MeecoBoard(
        id: "mini",
        title: "미니기기 / 음향",
        description: "스마트폰, PC, 카메라, 스피커와 음향기기",
        systemImage: "iphone",
        url: URL(string: "https://meeco.kr/mini")!,
        allowedBoardPaths: ["mini"],
        categories: [
            MeecoBoardCategory(id: "mini", title: "미니", url: URL(string: "https://meeco.kr/mini/category/23941713")!),
            MeecoBoardCategory(id: "audio", title: "음향", url: URL(string: "https://meeco.kr/mini/category/36923546")!),
            MeecoBoardCategory(id: "notice", title: "공지", url: URL(string: "https://meeco.kr/mini/category/23941775")!)
        ]
    )

    static let big = MeecoBoard(
        id: "big",
        title: "대형기기",
        description: "TV, 모니터, 생활가전, 차량 이야기",
        systemImage: "tv.fill",
        url: URL(string: "https://meeco.kr/big")!,
        allowedBoardPaths: ["big"],
        categories: [
            MeecoBoardCategory(id: "vehicle", title: "차량", url: URL(string: "https://meeco.kr/big/category/28110654")!),
            MeecoBoardCategory(id: "tv", title: "TV", url: URL(string: "https://meeco.kr/big/category/28110676")!),
            MeecoBoardCategory(id: "life", title: "생활", url: URL(string: "https://meeco.kr/big/category/28110645")!)
        ]
    )

    static let ai = MeecoBoard(
        id: "ai",
        title: "AI / 로봇",
        description: "AI, 로봇, 자동화 기술 이야기",
        systemImage: "cpu.fill",
        url: URL(string: "https://meeco.kr/AI")!,
        allowedBoardPaths: ["AI"],
        categories: [
            MeecoBoardCategory(id: "ai", title: "AI", url: URL(string: "https://meeco.kr/AI/category/38624667")!),
            MeecoBoardCategory(id: "robot", title: "로봇", url: URL(string: "https://meeco.kr/AI/category/38624668")!)
        ]
    )

    static let free = MeecoBoard(
        id: "free",
        title: "자유 게시판",
        description: "자유로운 주제의 커뮤니티 글",
        systemImage: "bubble.left.and.bubble.right.fill",
        url: URL(string: "https://meeco.kr/free")!,
        allowedBoardPaths: ["free"]
    )

    static let humor = MeecoBoard(
        id: "humor",
        title: "유머 게시판",
        description: "유머와 가벼운 읽을거리",
        systemImage: "face.smiling.fill",
        url: URL(string: "https://meeco.kr/humor")!,
        allowedBoardPaths: ["humor"]
    )

    static let gallery = MeecoBoard(
        id: "gallery",
        title: "갤러리",
        description: "사진과 이미지 중심 게시물",
        systemImage: "photo.on.rectangle.angled",
        url: URL(string: "https://meeco.kr/Gallery")!,
        allowedBoardPaths: ["Gallery"]
    )

    static let anonymous = MeecoBoard(
        id: "anonymous",
        title: "익명 게시판",
        description: "익명으로 대화하는 파일럿 게시판",
        systemImage: "person.fill.questionmark",
        url: URL(string: "https://meeco.kr/anonymous")!,
        allowedBoardPaths: ["anonymous"]
    )

    static let review = MeecoBoard(
        id: "review",
        title: "리뷰 게시판",
        description: "회원 사용기와 제품 리뷰",
        systemImage: "star.bubble.fill",
        url: URL(string: "https://meeco.kr/Review")!,
        allowedBoardPaths: ["Review"],
        categories: [
            MeecoBoardCategory(id: "review", title: "리뷰", url: URL(string: "https://meeco.kr/Review/category/32500992")!),
            MeecoBoardCategory(id: "lecture", title: "강의", url: URL(string: "https://meeco.kr/Review/category/37269169")!)
        ]
    )

    static let price = MeecoBoard(
        id: "price",
        title: "특가 게시판",
        description: "할인, 특가, 구매 정보",
        systemImage: "tag.fill",
        url: URL(string: "https://meeco.kr/Price")!,
        allowedBoardPaths: ["Price"]
    )

    static let purchase = MeecoBoard(
        id: "purchase",
        title: "구매 할게요",
        description: "구매 요청과 구입 희망 글",
        systemImage: "cart.fill.badge.plus",
        url: URL(string: "https://meeco.kr/Purchase")!,
        allowedBoardPaths: ["Purchase"]
    )

    static let market = MeecoBoard(
        id: "market",
        title: "장터 게시판",
        description: "회원 간 중고 거래 게시판",
        systemImage: "bag.fill",
        url: URL(string: "https://meeco.kr/market")!,
        allowedBoardPaths: ["market"]
    )

    static let enterprise = MeecoBoard(
        id: "enterprise",
        title: "홍보 게시판",
        description: "이벤트, 제휴, 홍보 게시물",
        systemImage: "megaphone.fill",
        url: URL(string: "https://meeco.kr/Enterprise")!,
        allowedBoardPaths: ["Enterprise"]
    )

    static let event = MeecoBoard(
        id: "event",
        title: "이벤트 참여",
        description: "이벤트 참여 게시판",
        systemImage: "sparkles",
        url: URL(string: "https://meeco.kr/Event")!,
        allowedBoardPaths: ["Event"]
    )

    static let bugUpdate = MeecoBoard(
        id: "bugUpdate",
        title: "개선 목록",
        description: "사이트 개선 및 운영 참여",
        systemImage: "checklist",
        url: URL(string: "https://meeco.kr/BugUpdate")!,
        allowedBoardPaths: ["BugUpdate"]
    )

    static let notice = MeecoBoard(
        id: "notice",
        title: "공지사항",
        description: "운영 공지와 사이트 안내",
        systemImage: "megaphone.fill",
        url: URL(string: "https://meeco.kr/notice")!,
        allowedBoardPaths: ["notice"]
    )

    static let allBoards: [MeecoBoard] = [
        .all, .monthly, .makgora, .balloon, .hot, .news, .mini, .review, .big, .ai,
        .free, .humor, .gallery, .anonymous, .price, .purchase, .market, .enterprise,
        .event, .bugUpdate, .notice
    ]

    static func boards(matching ids: Set<String>) -> [MeecoBoard] {
        allBoards.filter { ids.contains($0.id) }
    }

    func pageURL(_ page: Int, category: MeecoBoardCategory? = nil) -> URL {
        let baseURL = category?.url ?? url
        guard page > 1,
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return baseURL
        }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "page" }
        queryItems.append(URLQueryItem(name: "page", value: String(page)))
        components.queryItems = queryItems
        return components.url ?? baseURL
    }

    func loginURL() -> URL {
        actionURL(act: "dispMemberLoginForm", category: nil)
    }

    func writeURL(category: MeecoBoardCategory?) -> URL {
        actionURL(act: "dispBoardWrite", category: category)
    }

    func searchURL(query: String, category: MeecoBoardCategory?) -> URL {
        var components = URLComponents(url: category?.url ?? url, resolvingAgainstBaseURL: false)
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var queryItems = components?.queryItems ?? []
        queryItems.removeAll { ["search_target", "search_keyword", "page"].contains($0.name) }
        queryItems.append(URLQueryItem(name: "search_target", value: "title_content"))
        queryItems.append(URLQueryItem(name: "search_keyword", value: trimmedQuery))
        components?.queryItems = queryItems
        return components?.url ?? url
    }

    private func actionURL(act: String, category: MeecoBoardCategory?) -> URL {
        var components = URLComponents(string: "https://meeco.kr/index.php")!
        var queryItems = [
            URLQueryItem(name: "mid", value: url.pathComponents.filter { $0 != "/" }.first ?? id),
            URLQueryItem(name: "act", value: act)
        ]

        if let categoryID = category?.categoryID {
            queryItems.append(URLQueryItem(name: "category", value: categoryID))
        }

        components.queryItems = queryItems
        return components.url ?? url
    }
}

struct MeecoBoardCategory: Identifiable, Hashable {
    let id: String
    let title: String
    let url: URL

    var categoryID: String? {
        url.pathComponents.filter { $0 != "/" }.last
    }
}

struct MeecoPost: Identifiable, Equatable {
    let id: URL
    let documentID: String
    let title: String
    let nickname: String
    let date: String
    let url: URL
    let boardPath: String
    let category: String?
    let commentCount: Int?
    let upvoteCount: Int
    let isNotice: Bool
    let isHot: Bool
    var categoryColorHex: String? = nil
    var thumbnailURL: URL? = nil

    var commentURL: URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = "comment"
        return components?.url ?? url
    }

    var isEndedSpecialDeal: Bool {
        guard boardPath == "Price" else { return false }
        let normalizedTitle = title.normalizedPostTitle
        return normalizedTitle == "종료"
            || normalizedTitle == "[종료]"
            || normalizedTitle.hasPrefix("[종료]")
            || normalizedTitle.hasPrefix("종료 ")
    }
}

struct MeecoWebAction: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
}

struct MeecoLoginForm: Equatable {
    let actionURL: URL
    let method: String
    let userIDField: String
    let passwordField: String
    let keepSignedField: String?
    let keepSignedDefaultValue: String?
    let validatorID: String?
    let signUpURL: URL?
    let findAccountURL: URL?
    var hiddenFields: [String: String] = [:]
}

struct MeecoAuthStatus: Equatable {
    var isLoggedIn: Bool
    var displayName: String?
}

struct MeecoLoginCredentials {
    let userID: String
    let password: String
    let keepSigned: Bool
}

struct MeecoBoardSnapshot {
    let posts: [MeecoPost]
    let page: Int
    let sourceFingerprint: Int
    let fetchedAt: Date
}

struct MeecoPostDetail: Equatable {
    let title: String
    let nickname: String
    let date: String
    let body: String
    let bodyBlocks: [MeecoPostBodyBlock]
    let media: [MeecoMedia]
    let comments: [MeecoComment]
    let dealInfo: MeecoDealInfo?
}

struct MeecoPostBodyBlock: Identifiable, Equatable {
    enum Content: Equatable {
        case text(String)
        case linkPreview(MeecoMedia)
    }

    let id: Int
    let content: Content
}

struct MeecoDealInfo: Equatable {
    let status: String?
    let links: [MeecoDealLink]
}

struct MeecoDealLink: Identifiable, Equatable {
    let id: URL
    let title: String
    let url: URL
    var isRevenueGenerating = false
}

struct MeecoMedia: Identifiable, Equatable {
    enum Kind: Equatable {
        case image
        case video
        case linkPreview
    }

    let id: URL
    let url: URL
    let altText: String
    let kind: Kind
}

struct MeecoComment: Identifiable, Equatable {
    let id = UUID()
    let nickname: String
    let date: String
    let body: String
    let media: [MeecoMedia]
    let upvoteCount: Int
    let replyDepth: Int
    let isPostAuthor: Bool
}

struct MeecoAttendanceSnapshot: Equatable {
    let statusMessage: String
    let isCheckedInToday: Bool
    let cumulativeAttendanceDays: Int?
    let attendedDates: [String]
    let records: [MeecoAttendanceRecord]
    let fetchedAt: Date
}

struct MeecoAttendanceRecord: Identifiable, Equatable {
    let id = UUID()
    let rank: Int?
    let nickname: String
    let message: String
    let time: String
    let points: Int?
}

struct MeecoNotificationSnapshot: Equatable {
    let unreadCount: Int
    let notifications: [MeecoNotification]
    let fetchedAt: Date
}

struct MeecoNotification: Identifiable, Equatable {
    let id: String
    let title: String
    let body: String
    let date: String
    let url: URL?
    let isUnread: Bool
}

@MainActor
final class BoardViewModel: ObservableObject {
    enum LoadingState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var posts: [MeecoPost] = []
    @Published private(set) var state: LoadingState = .idle
    @Published private(set) var lastUpdatedAt: Date?
    @Published private(set) var isLoadingNextPage = false
    @Published private(set) var canLoadMore = true
    @Published private(set) var selectedCategory: MeecoBoardCategory?
    @Published private(set) var hasPendingLatestPosts = false
    @Published private(set) var shouldPromptForUpdate = false
    @Published private(set) var pendingLatestPostCount = 0
    @Published private(set) var refreshStatusMessage: String?

    private let board: MeecoBoard
    private let service: MeecoService
    private var sourceFingerprint: Int?
    private var pageCache: [Int: MeecoBoardSnapshot] = [:]
    private var pendingLatestSnapshot: MeecoBoardSnapshot?
    private var nextPage = 2
    private var requestGeneration = 0
    private var lastNextPageRequestAt = Date.distantPast
    private let minimumNextPageInterval: TimeInterval = 2.5

    init(board: MeecoBoard, service: MeecoService = MeecoService()) {
        self.board = board
        self.service = service
    }

    func load(force: Bool = false) async {
        guard force || state != .loading else { return }
        requestGeneration += 1
        let generation = requestGeneration
        state = .loading
        pageCache.removeAll()
        pendingLatestSnapshot = nil
        hasPendingLatestPosts = false
        shouldPromptForUpdate = false
        pendingLatestPostCount = 0
        refreshStatusMessage = nil
        nextPage = 2
        canLoadMore = true
        await fetchAndApply(page: 1, refreshLatest: false, generation: generation)
    }

    func markListMayBeStale() {
        guard !posts.isEmpty else { return }
        shouldPromptForUpdate = false
    }

    func checkForLatestPosts() async {
        guard state != .loading else { return }
        do {
            let snapshot = try await service.fetchBoardSnapshot(for: board, page: 1, category: selectedCategory)
            lastUpdatedAt = snapshot.fetchedAt
            guard isDifferentLatest(snapshot) else {
                applyMetadataRefresh(snapshot)
                pendingLatestSnapshot = nil
                hasPendingLatestPosts = false
                shouldPromptForUpdate = false
                pendingLatestPostCount = 0
                return
            }
            let newCount = newPostCount(in: snapshot)
            guard newCount > 0 else {
                applyMetadataRefresh(snapshot)
                pendingLatestSnapshot = nil
                hasPendingLatestPosts = false
                shouldPromptForUpdate = false
                pendingLatestPostCount = 0
                return
            }

            pendingLatestSnapshot = snapshot
            hasPendingLatestPosts = true
            shouldPromptForUpdate = true
            pendingLatestPostCount = newCount
        } catch {
            if posts.isEmpty {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func applyLatestPosts() async {
        guard state != .loading else { return }
        if let pendingLatestSnapshot {
            applyLatestSnapshotIfNeeded(pendingLatestSnapshot)
            self.pendingLatestSnapshot = nil
            return
        }

        do {
            let snapshot = try await service.fetchBoardSnapshot(for: board, page: 1, category: selectedCategory)
            applyLatestSnapshotIfNeeded(snapshot)
        } catch {
            if posts.isEmpty {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func clearRefreshStatusMessage(_ message: String?) {
        guard refreshStatusMessage == message else { return }
        refreshStatusMessage = nil
    }

    var topUpvotedPosts: [MeecoPost] {
        Array(posts
            .filter { $0.upvoteCount > 0 }
            .sorted { lhs, rhs in
                if lhs.upvoteCount == rhs.upvoteCount {
                    return lhs.date > rhs.date
                }
                return lhs.upvoteCount > rhs.upvoteCount
            }
            .prefix(3))
    }

    func selectCategory(_ category: MeecoBoardCategory?) async {
        guard selectedCategory != category else { return }
        selectedCategory = category
        posts = []
        sourceFingerprint = nil
        pendingLatestSnapshot = nil
        hasPendingLatestPosts = false
        shouldPromptForUpdate = false
        pendingLatestPostCount = 0
        refreshStatusMessage = nil
        await load(force: true)
    }

    func loadNextPageIfNeeded(after post: MeecoPost) async {
        guard canLoadMore,
              !isLoadingNextPage,
              post.id == posts.last?.id else {
            return
        }

        let elapsed = Date().timeIntervalSince(lastNextPageRequestAt)
        if elapsed < minimumNextPageInterval {
            let delay = minimumNextPageInterval - elapsed
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        guard canLoadMore, !isLoadingNextPage else { return }
        isLoadingNextPage = true
        lastNextPageRequestAt = Date()
        defer { isLoadingNextPage = false }

        let page = nextPage
        do {
            let snapshot: MeecoBoardSnapshot
            if let cachedSnapshot = pageCache[page] {
                snapshot = cachedSnapshot
            } else {
                snapshot = try await service.fetchBoardSnapshot(for: board, page: page, category: selectedCategory)
                pageCache[page] = snapshot
            }

            let originalCount = posts.count
            posts = merged(posts + snapshot.posts)
            lastUpdatedAt = snapshot.fetchedAt

            if snapshot.posts.isEmpty || posts.count == originalCount {
                canLoadMore = false
            } else {
                nextPage += 1
            }
        } catch {
            canLoadMore = false
        }
    }

    private func fetchAndApply(page: Int, refreshLatest: Bool, generation: Int? = nil) async {
        do {
            let snapshot = try await service.fetchBoardSnapshot(for: board, page: page, category: selectedCategory)
            if let generation, generation != requestGeneration {
                return
            }
            pageCache[page] = snapshot
            if page == 1 {
                applyPageOneSnapshot(snapshot)
            } else if refreshLatest || snapshot.sourceFingerprint != sourceFingerprint {
                posts = merged(posts + snapshot.posts)
                sourceFingerprint = snapshot.sourceFingerprint
            }
            lastUpdatedAt = snapshot.fetchedAt
            state = .loaded
        } catch {
            if posts.isEmpty {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func merged(_ posts: [MeecoPost]) -> [MeecoPost] {
        var seen = Set<URL>()
        return posts.filter { seen.insert($0.url).inserted }
    }

    private func applyPageOneSnapshot(_ snapshot: MeecoBoardSnapshot) {
        pageCache[1] = snapshot
        posts = merged(snapshot.posts + pageCache.keys.sorted().filter { $0 > 1 }.flatMap { pageCache[$0]?.posts ?? [] })
        sourceFingerprint = snapshot.sourceFingerprint
        lastUpdatedAt = snapshot.fetchedAt
        hasPendingLatestPosts = false
        shouldPromptForUpdate = false
        pendingLatestPostCount = 0
    }

    private func isDifferentLatest(_ snapshot: MeecoBoardSnapshot) -> Bool {
        let currentIDs = pageCache[1]?.posts.map(\.id) ?? Array(posts.prefix(snapshot.posts.count)).map(\.id)
        return currentIDs != snapshot.posts.map(\.id)
    }

    private func applyLatestSnapshotIfNeeded(_ snapshot: MeecoBoardSnapshot) {
        let newCount = newPostCount(in: snapshot)
        pendingLatestSnapshot = nil
        hasPendingLatestPosts = false
        shouldPromptForUpdate = false
        pendingLatestPostCount = 0

        guard newCount > 0 else {
            applyMetadataRefresh(snapshot)
            lastUpdatedAt = snapshot.fetchedAt
            refreshStatusMessage = "새 게시물이 없습니다."
            state = .loaded
            return
        }

        applyPageOneSnapshot(snapshot)
        refreshStatusMessage = "새 게시물 \(newCount)개를 불러왔습니다."
        state = .loaded
    }

    private func newPostCount(in snapshot: MeecoBoardSnapshot) -> Int {
        guard let currentFirstID = pageCache[1]?.posts.first?.id ?? posts.first?.id,
              let currentFirstIndex = snapshot.posts.firstIndex(where: { $0.id == currentFirstID }) else {
            return 0
        }

        let currentIDs = Set(posts.map(\.id))
        return snapshot.posts
            .prefix(currentFirstIndex)
            .filter { !currentIDs.contains($0.id) }
            .count
    }

    private func applyMetadataRefresh(_ snapshot: MeecoBoardSnapshot) {
        guard !posts.isEmpty else {
            applyPageOneSnapshot(snapshot)
            return
        }

        let existingIDs = Set(posts.map(\.id))
        guard snapshot.posts.contains(where: { existingIDs.contains($0.id) }) else { return }

        let replacements = Dictionary(uniqueKeysWithValues: snapshot.posts.map { ($0.id, $0) })
        posts = posts.map { replacements[$0.id] ?? $0 }
        if let cachedPageOne = pageCache[1] {
            pageCache[1] = MeecoBoardSnapshot(
                posts: cachedPageOne.posts.map { replacements[$0.id] ?? $0 },
                page: cachedPageOne.page,
                sourceFingerprint: snapshot.sourceFingerprint,
                fetchedAt: snapshot.fetchedAt
            )
        } else {
            pageCache[1] = snapshot
        }
        sourceFingerprint = snapshot.sourceFingerprint
    }
}

struct BoardView: View {
    let board: MeecoBoard

    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var authSession: MeecoAuthSession
    @StateObject private var viewModel: BoardViewModel
    @State private var webAction: MeecoWebAction?
    @State private var searchText = ""
    @State private var isLoginRequired = false
    @AppStorage("favoriteBoardIDs") private var favoriteBoardIDsStorage = ""
    private let refreshTimer = Timer.publish(every: 120, on: .main, in: .common).autoconnect()

    init(board: MeecoBoard) {
        self.board = board
        _viewModel = StateObject(wrappedValue: BoardViewModel(board: board))
    }

    var body: some View {
        VStack(spacing: 0) {
            if !board.categories.isEmpty {
                CategoryTabBar(
                    categories: board.categories,
                    selectedCategory: viewModel.selectedCategory
                ) { category in
                    Task { await viewModel.selectCategory(category) }
                }
            }

            if viewModel.shouldPromptForUpdate {
                LatestPostsPrompt(newPostCount: viewModel.pendingLatestPostCount) {
                    Task { await viewModel.applyLatestPosts() }
                }
            }

            if let refreshStatusMessage = viewModel.refreshStatusMessage {
                RefreshStatusBanner(message: refreshStatusMessage)
            }

            Group {
                if viewModel.posts.isEmpty {
                    switch viewModel.state {
                    case .failed(let message):
                        VStack(spacing: 12) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("게시물을 불러오지 못했습니다")
                                .font(.headline)
                            Text(message)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("다시 시도") {
                                Task { await viewModel.load() }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    default:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    List {
                        Section {
                            ForEach(viewModel.posts) { post in
                                NavigationLink(destination: PostDetailView(post: post).hideRootTabBar()) {
                                    if board.id == MeecoBoard.gallery.id {
                                        GalleryPostRow(post: post)
                                    } else {
                                        PostRow(post: post, showsSourceBoardBadge: board.showsSourceBoardBadges)
                                    }
                                }
                                .onAppear {
                                    Task { await viewModel.loadNextPageIfNeeded(after: post) }
                                }
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.applyLatestPosts()
                    }

                    if viewModel.isLoadingNextPage {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(board.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.bar, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
#endif
        .hideRootTabBar()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    toggleFavoriteBoard()
                } label: {
                    Image(systemName: isFavoriteBoard ? "star.fill" : "star")
                }
                .accessibilityLabel(isFavoriteBoard ? "즐겨찾기 해제" : "즐겨찾기 추가")
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        openAuthenticatedWebAction(title: "글쓰기", url: board.writeURL(category: viewModel.selectedCategory))
                    } label: {
                        Label("글쓰기", systemImage: "square.and.pencil")
                    }

                    Button {
                        Task { await viewModel.applyLatestPosts() }
                    } label: {
                        Label("새로고침", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.state == .loading)

                    Button {
                        webAction = MeecoWebAction(title: board.title, url: board.pageURL(1, category: viewModel.selectedCategory))
                    } label: {
                        Label("웹에서 열기", systemImage: "safari")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("더보기")
            }
        }
        .safeAreaInset(edge: .bottom) {
            BoardBottomActionBar(
                searchText: $searchText,
                onSearch: submitSearch,
                onCompose: {
                    openAuthenticatedWebAction(title: "글쓰기", url: board.writeURL(category: viewModel.selectedCategory))
                }
            )
        }
        .sheet(item: $webAction) { action in
            WebActionView(action: action)
        }
        .sheet(isPresented: $isLoginRequired) {
            AccountSettingsView()
        }
        .task {
            await viewModel.load()
        }
        .onReceive(refreshTimer) { _ in
            Task { await viewModel.checkForLatestPosts() }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task { await viewModel.checkForLatestPosts() }
            } else if phase == .inactive || phase == .background {
                viewModel.markListMayBeStale()
            }
        }
        .onChange(of: viewModel.refreshStatusMessage) { message in
            guard let message else { return }
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                await MainActor.run {
                    viewModel.clearRefreshStatusMessage(message)
                }
            }
        }
    }

    private func submitSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        webAction = MeecoWebAction(
            title: "검색",
            url: board.searchURL(query: searchText, category: viewModel.selectedCategory)
        )
    }

    private func openAuthenticatedWebAction(title: String, url: URL) {
        if authSession.isLoggedIn {
            webAction = MeecoWebAction(title: title, url: url)
        } else {
            isLoginRequired = true
        }
    }

    private var isFavoriteBoard: Bool {
        favoriteBoardIDsStorage.boardIDSet.contains(board.id)
    }

    private func toggleFavoriteBoard() {
        var favoriteIDs = favoriteBoardIDsStorage.boardIDSet
        if favoriteIDs.contains(board.id) {
            favoriteIDs.remove(board.id)
        } else {
            favoriteIDs.insert(board.id)
        }
        favoriteBoardIDsStorage = favoriteIDs.boardIDStorageValue
    }
}

struct BoardBottomActionBar: View {
    @Binding var searchText: String
    let onSearch: () -> Void
    let onCompose: () -> Void

    var body: some View {
        BottomControlBackdrop {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("검색", text: $searchText)
                        .font(.body.weight(.semibold))
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .submitLabel(.search)
                        .onSubmit(onSearch)

                    Button(action: onSearch) {
                        Image(systemName: "arrow.forward.circle.fill")
                            .font(.title3)
                    }
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("검색")
                }
                .padding(.horizontal, 14)
                .frame(height: 50)
                .boardLiquidGlass(cornerRadius: 25)
                .shadow(color: .black.opacity(0.12), radius: 18, y: 8)

                Button(action: onCompose) {
                    Image(systemName: "square.and.pencil")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 50, height: 50)
                .boardLiquidGlassButton()
                .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
                .accessibilityLabel("글쓰기")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
    }
}

struct LatestPostsPrompt: View {
    let newPostCount: Int
    let onUpdate: () -> Void

    var body: some View {
        Button(action: onUpdate) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                Text(promptText)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("업데이트")
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(.accentColor)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.accentColor.opacity(0.12))
        }
        .buttonStyle(.plain)
    }

    private var promptText: String {
        if newPostCount > 0 {
            return "새 게시물 \(newPostCount)개가 있습니다. 위로 당겨 업데이트하세요."
        }

        return "게시물 목록이 최신이 아닐 수 있습니다. 위로 당겨 업데이트하세요."
    }
}

struct RefreshStatusBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
            Text(message)
                .font(.footnote.weight(.semibold))
            Spacer()
        }
        .foregroundColor(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.08))
    }
}

struct CategoryTabBar: View {
    let categories: [MeecoBoardCategory]
    let selectedCategory: MeecoBoardCategory?
    let onSelect: (MeecoBoardCategory?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryButton(title: "전체", category: nil)
                ForEach(categories) { category in
                    categoryButton(title: category.title, category: category)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private func categoryButton(title: String, category: MeecoBoardCategory?) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            onSelect(category)
        } label: {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
                .foregroundColor(isSelected ? .accentColor : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct PostRow: View {
    let post: MeecoPost
    var showsSourceBoardBadge = false

    private var isEndedDeal: Bool {
        post.isEndedSpecialDeal
    }

    private var leadingBadge: (title: String, color: Color)? {
        if let category = post.category?.nonEmpty {
            return (category, post.categoryBadgeColor)
        }

        if showsSourceBoardBadge, let sourceBoardTitle = post.sourceBoardTitle {
            return (sourceBoardTitle, post.sourceBoardBadgeColor)
        }

        if post.isNotice {
            return ("공지", .meecoCrimson)
        }

        return nil
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    if let leadingBadge {
                        PostBadge(
                            title: leadingBadge.title,
                            color: leadingBadge.color,
                            isDimmed: isEndedDeal
                        )
                    }

                    if post.isHot {
                        PostBadge(title: "핫글", color: .red, isDimmed: isEndedDeal)
                    }

                    Text(post.title)
                        .font(.body)
                        .foregroundColor(isEndedDeal ? .secondary : .primary)
                        .lineLimit(2)
                        .layoutPriority(1)
                }

                Text([post.nickname, post.date].filter { !$0.isEmpty }.joined(separator: " "))
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(isEndedDeal ? 0.72 : 1))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            PostStatsColumn(commentCount: post.commentCount, upvoteCount: post.upvoteCount, isDimmed: isEndedDeal)
        }
        .padding(.vertical, 6)
    }
}

struct PostBadge: View {
    let title: String
    let color: Color
    let isDimmed: Bool

    var body: some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 6)
            .frame(minWidth: 34, minHeight: 18, maxHeight: 18)
            .fixedSize(horizontal: true, vertical: false)
            .background((isDimmed ? Color.secondary : color).opacity(isDimmed ? 0.55 : 0.92))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct GalleryPostRow: View {
    let post: MeecoPost

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GalleryThumbnailView(url: post.thumbnailURL)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(post.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Text([post.nickname, post.date].filter { !$0.isEmpty }.joined(separator: " "))
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    GalleryInlineStat(systemImage: "heart.fill", count: post.upvoteCount, color: .pink)
                    GalleryInlineStat(systemImage: "text.bubble", count: post.commentCount ?? 0, color: .accentColor)
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct GalleryThumbnailView: View {
    let url: URL?

    private let thumbnailHeight: CGFloat = 190

    var body: some View {
        ZStack {
            placeholder

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, minHeight: thumbnailHeight, maxHeight: thumbnailHeight)
                            .clipped()
                    case .failure:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: thumbnailHeight, maxHeight: thumbnailHeight)
        .clipped()
    }

    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.08)
            Image(systemName: "photo")
                .font(.largeTitle.weight(.semibold))
                .foregroundColor(.secondary)
        }
    }
}

struct GalleryInlineStat: View {
    let systemImage: String
    let count: Int
    let color: Color

    var body: some View {
        if count > 0 {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                Text("\(count)")
                    .monospacedDigit()
            }
            .foregroundColor(color)
        }
    }
}

struct PostStatsColumn: View {
    let commentCount: Int?
    let upvoteCount: Int
    var isDimmed = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            statRow(systemImage: "heart.fill", count: upvoteCount, color: .pink)
            statRow(systemImage: "text.bubble", count: commentCount ?? 0, color: .accentColor)
        }
        .fixedSize(horizontal: true, vertical: false)
        .font(.caption.weight(.semibold))
    }

    @ViewBuilder
    private func statRow(systemImage: String, count: Int, color: Color) -> some View {
        if count > 0 {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .frame(width: 14)
                Text("\(count)")
                    .monospacedDigit()
            }
            .foregroundColor(isDimmed ? .secondary : color)
        } else {
            Color.clear.frame(width: 0, height: 14)
        }
    }
}

struct TopUpvotedPostRow: View {
    let rank: Int
    let post: MeecoPost

    var body: some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text([post.nickname, post.date].filter { !$0.isEmpty }.joined(separator: " "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Label("\(post.upvoteCount)", systemImage: "heart.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(.pink)
                .labelStyle(.titleAndIcon)
        }
        .padding(.vertical, 4)
    }
}

struct MediaStack: View {
    let media: [MeecoMedia]
    var onImageTap: (MeecoMedia) -> Void = { _ in }
    var onLinkTap: ((MeecoMedia) -> Void)?

    @Environment(\.openURL) private var openURL

    var body: some View {
        if !media.isEmpty {
            VStack(spacing: 10) {
                ForEach(media) { item in
                    mediaView(item)
                }
            }
        }
    }

    @ViewBuilder
    private func mediaView(_ item: MeecoMedia) -> some View {
        switch item.kind {
        case .image:
            Button {
                onImageTap(item)
            } label: {
                AsyncImage(url: item.url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 160)
                    case .success(let image):
                        hdrImage(image)
                    case .failure:
                        Label("이미지를 불러오지 못했습니다", systemImage: "photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 80)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.altText.isEmpty ? "첨부 이미지" : item.altText)
        case .video:
            VideoPlayer(player: AVPlayer(url: item.url))
                .frame(minHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case .linkPreview:
            Button {
                if let onLinkTap {
                    onLinkTap(item)
                } else {
                    openURL(item.url)
                }
            } label: {
                LinkPreviewCard(media: item)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func hdrImage(_ image: Image) -> some View {
        let fittedImage = image
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, minHeight: 160)

        if #available(iOS 17.0, macOS 14.0, *) {
            fittedImage
                .allowedDynamicRange(.high)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            fittedImage
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct LinkPreviewCard: View {
    let media: MeecoMedia

    var body: some View {
        HStack(spacing: 12) {
            if let thumbnailURL = media.url.youtubeThumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(systemName: media.url.previewSystemImage)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 96, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: media.url.previewSystemImage)
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 44)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(media.altText.nonEmpty ?? media.url.previewTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(media.url.host ?? media.url.absoluteString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct OriginalImageViewer: View {
    let media: MeecoMedia
    let onDismiss: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var exifRows: [ImageMetadataRow] = []
    @State private var originalImageFileURL: URL?
    @State private var isLoadingEXIF = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()

            AsyncImage(url: media.url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(.white)
                case .success(let image):
                    originalImage(image)
                case .failure:
                    VStack(spacing: 10) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                        Text("원본 이미지를 불러오지 못했습니다")
                            .font(.body)
                    }
                    .foregroundColor(.white.opacity(0.8))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, exifRows.isEmpty ? 0 : 142)
            .offset(y: max(0, dragOffset.height))
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        if value.translation.height > 90 || value.predictedEndTranslation.height > 160 {
                            onDismiss()
                        } else {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )

            VStack {
                Spacer()
                ImageMetadataOverlay(rows: exifRows, isLoading: isLoadingEXIF)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)

            HStack(spacing: 10) {
                if let originalImageFileURL {
                    ShareLink(item: originalImageFileURL) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.16))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("사진 저장")
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.white.opacity(0.16))
                        .clipShape(Circle())
                }
                .accessibilityLabel("닫기")
            }
            .padding(.top, 18)
            .padding(.trailing, 18)
        }
        .task(id: media.url) {
            await loadEXIF()
        }
    }

    @ViewBuilder
    private func originalImage(_ image: Image) -> some View {
        let fittedImage = image
            .resizable()
            .scaledToFit()
            .padding(12)

        if #available(iOS 17.0, macOS 14.0, *) {
            fittedImage.allowedDynamicRange(.high)
        } else {
            fittedImage
        }
    }

    private func loadEXIF() async {
        isLoadingEXIF = true
        defer { isLoadingEXIF = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: media.url)
            exifRows = ImageMetadataReader.rows(from: data)
            originalImageFileURL = try temporaryImageFileURL(for: data)
        } catch {
            exifRows = []
            originalImageFileURL = nil
        }
    }

    private func temporaryImageFileURL(for data: Data) throws -> URL {
        let fileExtension = media.url.pathExtension.nonEmpty ?? "jpg"
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("meeco-original-\(media.id.hashValue)")
            .appendingPathExtension(fileExtension)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}

struct ImageMetadataRow: Identifiable, Equatable {
    let id: String
    let label: String
    let value: String
}

struct ImageMetadataOverlay: View {
    let rows: [ImageMetadataRow]
    let isLoading: Bool

    var body: some View {
        if isLoading || !rows.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.metering.center.weighted")
                    Text("EXIF")
                        .font(.caption.weight(.bold))
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    }
                    Spacer()
                }

                ForEach(rows) { row in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(row.label)
                            .foregroundColor(.white.opacity(0.62))
                            .frame(width: 82, alignment: .leading)
                        Text(row.value)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .font(.caption)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundColor(.white)
        }
    }
}

enum ImageMetadataReader {
    static func rows(from data: Data) -> [ImageMetadataRow] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return []
        }

        let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] ?? [:]
        let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] ?? [:]
        var rows: [ImageMetadataRow] = []
        append("camera", "Camera", [string(tiff[kCGImagePropertyTIFFMake as String]), string(tiff[kCGImagePropertyTIFFModel as String])].compactMap { $0 }.joined(separator: " "), to: &rows)
        append("lens", "Lens", string(exif[kCGImagePropertyExifLensModel as String]), to: &rows)
        append("date", "Date", string(exif[kCGImagePropertyExifDateTimeOriginal as String]) ?? string(tiff[kCGImagePropertyTIFFDateTime as String]), to: &rows)
        append("focal", "Focal", rational(exif[kCGImagePropertyExifFocalLength as String]).map { "\($0) mm" }, to: &rows)
        append("aperture", "Aperture", rational(exif[kCGImagePropertyExifFNumber as String]).map { "f/\($0)" }, to: &rows)
        append("exposure", "Shutter", exposureTime(exif[kCGImagePropertyExifExposureTime as String]), to: &rows)
        append("iso", "ISO", intList(exif[kCGImagePropertyExifISOSpeedRatings as String]), to: &rows)
        append("size", "Size", imageSize(properties), to: &rows)
        return rows
    }

    private static func append(_ id: String, _ label: String, _ value: String?, to rows: inout [ImageMetadataRow]) {
        guard let value, !value.isEmpty else { return }
        rows.append(ImageMetadataRow(id: id, label: label, value: value))
    }

    private static func string(_ value: Any?) -> String? {
        if let string = value as? String {
            return string.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }

    private static func rational(_ value: Any?) -> String? {
        guard let number = value as? NSNumber else { return nil }
        let doubleValue = number.doubleValue
        guard doubleValue > 0 else { return nil }
        return String(format: doubleValue >= 10 ? "%.0f" : "%.1f", doubleValue)
    }

    private static func exposureTime(_ value: Any?) -> String? {
        guard let number = value as? NSNumber else { return nil }
        let seconds = number.doubleValue
        guard seconds > 0 else { return nil }
        if seconds < 1 {
            return "1/\(Int(round(1 / seconds))) s"
        }
        return String(format: "%.1f s", seconds)
    }

    private static func intList(_ value: Any?) -> String? {
        if let array = value as? [Any] {
            return array.compactMap { string($0) }.joined(separator: ", ").nonEmpty
        }
        return string(value)
    }

    private static func imageSize(_ properties: [String: Any]) -> String? {
        guard let width = properties[kCGImagePropertyPixelWidth as String] as? NSNumber,
              let height = properties[kCGImagePropertyPixelHeight as String] as? NSNumber else {
            return nil
        }
        return "\(width.intValue) x \(height.intValue)"
    }

}

private extension View {
    @ViewBuilder
    func showRootTabBar() -> some View {
        self
    }

    @ViewBuilder
    func hideRootTabBar() -> some View {
        self
    }

    @ViewBuilder
    func boardLiquidGlass(cornerRadius: CGFloat) -> some View {
#if os(iOS)
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.tint(.white.opacity(0.14)).interactive(), in: .rect(cornerRadius: cornerRadius))
                .shadow(color: .white.opacity(0.16), radius: 10, y: -2)
                .shadow(color: .black.opacity(0.10), radius: 18, y: 8)
        } else {
            self
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: .black.opacity(0.10), radius: 18, y: 8)
        }
#else
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.10), radius: 18, y: 8)
#endif
    }

    @ViewBuilder
    func boardLiquidGlassButton() -> some View {
#if os(iOS)
        if #available(iOS 26.0, *) {
            self
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(.white.opacity(0.18)).interactive(), in: Circle())
                .clipShape(Circle())
                .shadow(color: .white.opacity(0.18), radius: 8, y: -2)
                .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
        } else {
            self
                .buttonStyle(.bordered)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
        }
#else
        self
            .buttonStyle(.bordered)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
#endif
    }

    @ViewBuilder
    func rootProminentLiquidGlassButton() -> some View {
#if os(iOS)
        if #available(iOS 26.0, *) {
            self
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(.accentColor).interactive(), in: Circle())
                .clipShape(Circle())
        } else {
            self
                .buttonStyle(.plain)
                .background(Color.accentColor)
                .clipShape(Circle())
        }
#else
        self
            .buttonStyle(.plain)
            .background(Color.accentColor)
            .clipShape(Circle())
#endif
    }

    @ViewBuilder
    func hideTabBarWhileReading() -> some View {
        self.hideRootTabBar()
    }
}

@MainActor
final class PostDetailViewModel: ObservableObject {
    enum LoadingState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var detail: MeecoPostDetail?
    @Published private(set) var state: LoadingState = .idle

    private let post: MeecoPost
    private let service: MeecoService

    init(post: MeecoPost, service: MeecoService = MeecoService()) {
        self.post = post
        self.service = service
    }

    func load() async {
        guard state != .loading else { return }
        state = .loading
        do {
            detail = try await service.fetchPostDetail(for: post)
            state = .loaded
        } catch is CancellationError {
            state = detail == nil ? .idle : .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

struct PostDetailView: View {
    let post: MeecoPost

    @EnvironmentObject private var authSession: MeecoAuthSession
    @StateObject private var viewModel: PostDetailViewModel
    @State private var webAction: MeecoWebAction?
    @State private var selectedComment: MeecoComment?
    @State private var selectedImage: MeecoMedia?
    @State private var isLoginRequired = false

    init(post: MeecoPost) {
        self.post = post
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }

    var body: some View {
        Group {
            if let detail = viewModel.detail {
                detailContent(detail)
            } else {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed(let message):
                    fallbackWebContent(message: message)
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle("")
        .safeAreaInset(edge: .bottom) {
            PostCommentActionBar {
                openAuthenticatedWebAction(title: "댓글 쓰기", url: post.commentURL)
            }
        }
        .sheet(item: $webAction) { action in
            WebActionView(action: action)
        }
        .sheet(isPresented: $isLoginRequired) {
            AccountSettingsView()
        }
        .fullScreenCover(item: $selectedImage) { media in
            OriginalImageViewer(media: media) {
                selectedImage = nil
            }
        }
        .confirmationDialog(
            "댓글 작업",
            isPresented: Binding(
                get: { selectedComment != nil },
                set: { isPresented in
                    if !isPresented {
                        selectedComment = nil
                    }
                }
            ),
            presenting: selectedComment
        ) { comment in
            Button {
                openAuthenticatedWebAction(title: "댓글 추천", url: post.commentURL)
            } label: {
                Label("추천하기", systemImage: "heart")
            }

            Button {
                openAuthenticatedWebAction(title: "답글 쓰기", url: post.commentURL)
            } label: {
                Label("답글 쓰기", systemImage: "arrowshape.turn.up.left")
            }
        } message: { comment in
            Text([comment.nickname, comment.date].filter { !$0.isEmpty }.joined(separator: " "))
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .hideTabBarWhileReading()
    }

    private func openAuthenticatedWebAction(title: String, url: URL) {
        if authSession.isLoggedIn {
            webAction = MeecoWebAction(title: title, url: url)
        } else {
            isLoginRequired = true
        }
    }

    private func fallbackWebContent(message: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.secondary)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Spacer()
                Button("다시 시도") {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.bordered)
            }
            .padding()

            WebArticleView(url: post.url)
        }
    }

    private func detailContent(_ detail: MeecoPostDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(detail.title)
                        .font(.title2.weight(.bold))
                    HStack {
                        Text(detail.nickname)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(detail.date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let dealInfo = detail.dealInfo {
                        SpecialDealInfoView(dealInfo: dealInfo)
                    }
                }

                PostBodyBlocksView(
                    blocks: detail.bodyBlocks,
                    fallbackBody: detail.body,
                    onLinkTap: { media in
                        webAction = MeecoWebAction(title: media.url.previewTitle, url: media.url)
                    }
                )

                MediaStack(
                    media: detail.media.filter { $0.kind != .linkPreview },
                    onImageTap: { media in
                        selectedImage = media
                    }
                )

                if !detail.comments.isEmpty {
                    CommentsHeader(count: detail.comments.count)
                    CommentThreadList(
                        comments: detail.comments,
                        onImageTap: { media in selectedImage = media }
                    ) { comment in
                        selectedComment = comment
                    }
                }
            }
            .padding()
            .padding(.bottom, 76)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PostBodyBlocksView: View {
    let blocks: [MeecoPostBodyBlock]
    let fallbackBody: String
    let onLinkTap: (MeecoMedia) -> Void

    var body: some View {
        if blocks.isEmpty {
            Text(fallbackBody)
                .font(.body)
                .lineSpacing(5)
                .textSelection(.enabled)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(blocks) { block in
                    switch block.content {
                    case .text(let text):
                        Text(text)
                            .font(.body)
                            .lineSpacing(5)
                            .textSelection(.enabled)
                    case .linkPreview(let media):
                        Button {
                            onLinkTap(media)
                        } label: {
                            LinkPreviewCard(media: media)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct SpecialDealInfoView: View {
    let dealInfo: MeecoDealInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let status = dealInfo.status {
                Label(status, systemImage: status == "종료" ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(status == "종료" ? .secondary : .green)
            }

            if !dealInfo.links.isEmpty {
                HStack(spacing: 8) {
                    ForEach(dealInfo.links.prefix(3)) { link in
                        Link(destination: link.url) {
                            Label(link.title, systemImage: link.isRevenueGenerating ? "cart.fill.badge.plus" : "cart.fill")
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                                .foregroundColor(link.isRevenueGenerating ? .black.opacity(0.82) : .accentColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background((link.isRevenueGenerating ? Color.yellow : Color.accentColor).opacity(link.isRevenueGenerating ? 0.88 : 0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.top, 4)
    }
}

struct PostCommentActionBar: View {
    let onWriteComment: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: onWriteComment) {
                Image(systemName: "text.bubble.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
            }
            .accessibilityLabel("댓글 쓰기")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

struct CommentsHeader: View {
    let count: Int

    var body: some View {
        HStack {
            Text("댓글")
                .font(.headline)
            Text("\(count)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

struct CommentCard: View {
    let comment: MeecoComment
    let onImageTap: (MeecoMedia) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Text(comment.nickname.nonEmpty ?? "익명")
                        .font(.caption.weight(.semibold))
                    if comment.isPostAuthor {
                        Text("작성자")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(authorBadgeForeground)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(authorBadgeBackground)
                            .clipShape(Capsule())
                    }
                }
                Spacer(minLength: 8)
                Text(comment.date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(comment.body)
                .font(.body)
                .foregroundColor(.primary)
                .textSelection(.enabled)

            MediaStack(media: comment.media, onImageTap: onImageTap)

            if comment.upvoteCount > 0 {
                Label("\(comment.upvoteCount)", systemImage: "heart.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.pink)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(cardStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var cardBackground: Color {
        if comment.isPostAuthor {
            return colorScheme == .dark ? Color.orange.opacity(0.20) : Color.orange.opacity(0.12)
        }

        if colorScheme == .dark {
            return comment.replyDepth > 0 ? Color.white.opacity(0.085) : Color.white.opacity(0.055)
        }

        return comment.replyDepth > 0 ? Color.accentColor.opacity(0.075) : Color.accentColor.opacity(0.045)
    }

    private var cardStroke: Color {
        if comment.isPostAuthor {
            return colorScheme == .dark ? Color.orange.opacity(0.50) : Color.orange.opacity(0.34)
        }

        if colorScheme == .dark {
            return comment.replyDepth > 0 ? Color.white.opacity(0.24) : Color.white.opacity(0.14)
        }

        return comment.replyDepth > 0 ? Color.accentColor.opacity(0.22) : Color.accentColor.opacity(0.12)
    }

    private var authorBadgeForeground: Color {
        colorScheme == .dark ? .black : .white
    }

    private var authorBadgeBackground: Color {
        colorScheme == .dark ? Color.orange.opacity(0.95) : Color.orange
    }
}

struct CommentThreadList: View {
    let comments: [MeecoComment]
    let onImageTap: (MeecoMedia) -> Void
    let onSelect: (MeecoComment) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(comments.enumerated()), id: \.element.id) { index, comment in
                Button {
                    onSelect(comment)
                } label: {
                    CommentThreadRow(
                        comment: comment,
                        activeAncestorDepths: activeAncestorDepths(for: index),
                        continuesCurrentDepth: continuesCurrentDepth(for: index),
                        onImageTap: onImageTap
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func activeAncestorDepths(for index: Int) -> Set<Int> {
        guard comments[index].replyDepth > 0 else { return [] }

        let currentDepth = min(max(comments[index].replyDepth, 0), 3)
        let followingDepths = comments.dropFirst(index + 1)
            .prefix { $0.replyDepth > 0 }
            .map { min(max($0.replyDepth, 0), 3) }

        return Set((1..<currentDepth).filter { depth in
            followingDepths.contains { $0 >= depth }
        })
    }

    private func continuesCurrentDepth(for index: Int) -> Bool {
        let currentDepth = min(max(comments[index].replyDepth, 0), 3)
        guard currentDepth > 0, comments.indices.contains(index + 1) else { return false }
        return min(max(comments[index + 1].replyDepth, 0), 3) > currentDepth
    }
}

struct CommentThreadRow: View {
    let comment: MeecoComment
    let activeAncestorDepths: Set<Int>
    let continuesCurrentDepth: Bool
    let onImageTap: (MeecoMedia) -> Void

    private var clampedDepth: Int {
        min(max(comment.replyDepth, 0), 3)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if clampedDepth > 0 {
                ReplyTreeGuides(
                    depth: clampedDepth,
                    activeAncestorDepths: activeAncestorDepths,
                    continuesCurrentDepth: continuesCurrentDepth
                )
            }

            CommentCard(comment: comment, onImageTap: onImageTap)
        }
    }
}

struct ReplyTreeGuides: View {
    let depth: Int
    let activeAncestorDepths: Set<Int>
    let continuesCurrentDepth: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<depth, id: \.self) { index in
                if index == depth - 1 {
                    ReplyConnector(continues: continuesCurrentDepth)
                } else if activeAncestorDepths.contains(index + 1) {
                    ReplyContinuation()
                } else {
                    Color.clear.frame(width: 18, height: 58)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct ReplyContinuation: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(lineColor)
            .frame(width: 1, height: 58)
            .frame(width: 18)
    }

    private var lineColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.34) : Color.secondary.opacity(0.26)
    }
}

struct ReplyConnector: View {
    let continues: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(lineColor)
                .frame(width: 1, height: continues ? 58 : 25)
                .padding(.leading, 8)

            Rectangle()
                .fill(lineColor)
                .frame(width: 16, height: 1)
                .padding(.top, 24)
                .padding(.leading, 8)
        }
        .frame(width: 24, height: 58)
    }

    private var lineColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.42) : Color.secondary.opacity(0.34)
    }
}

@MainActor
final class MeecoAuthSession: ObservableObject {
    enum Status: Equatable {
        case unknown
        case checking
        case loggedOut
        case loggedIn(String?)
        case failed(String)
    }

    @Published private(set) var status: Status = .unknown
    @Published private(set) var loginForm: MeecoLoginForm?
    @Published var userID = ""
    @Published var password = ""
    @Published var keepSigned = true

    private let service: MeecoService

    init(service: MeecoService = MeecoService()) {
        self.service = service
    }

    var isLoggedIn: Bool {
        if case .loggedIn = status { return true }
        return false
    }

    var statusText: String {
        switch status {
        case .unknown, .checking:
            return "로그인 상태 확인 중"
        case .loggedOut:
            return "로그인이 필요합니다"
        case .loggedIn(let displayName):
            return [displayName, "로그인됨"].compactMap { $0?.nonEmpty }.joined(separator: " ")
        case .failed(let message):
            return message
        }
    }

    func verifySession() async {
        status = .checking
        do {
            let verifiedStatus = try await service.fetchAuthStatus()
            await apply(status: verifiedStatus)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func prepareLoginForm() async {
        guard loginForm == nil else { return }
        guard !isLoggedIn else { return }
        do {
            loginForm = try await service.fetchLoginForm()
            if case .checking = status {
                status = .loggedOut
            } else if case .unknown = status {
                status = .loggedOut
            }
        } catch {
            if isLoggedIn {
                return
            }
            status = .failed(error.localizedDescription)
        }
    }

    func login() async {
        let trimmedUserID = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUserID.isEmpty, !password.isEmpty else {
            status = .failed("아이디와 비밀번호를 입력해 주세요.")
            return
        }

        status = .checking
        do {
            let form: MeecoLoginForm
            if let currentLoginForm = loginForm {
                form = currentLoginForm
            } else {
                form = try await service.fetchLoginForm()
            }
            loginForm = form
            let verifiedStatus = try await service.login(
                credentials: MeecoLoginCredentials(
                    userID: trimmedUserID,
                    password: password,
                    keepSigned: keepSigned
                ),
                form: form
            )
            password = ""
            await apply(status: verifiedStatus)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func logout() async {
        await service.clearSessionCookies()
        userID = ""
        password = ""
        status = .loggedOut
        loginForm = nil
    }

    private func apply(status authStatus: MeecoAuthStatus) async {
        if authStatus.isLoggedIn {
            status = .loggedIn(authStatus.displayName)
            loginForm = nil
        } else {
            status = .loggedOut
            await prepareLoginForm()
        }
    }
}

@MainActor
final class AccountSettingsViewModel: ObservableObject {
    enum LoadingState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var loginForm: MeecoLoginForm?
    @Published private(set) var state: LoadingState = .idle

    private let service: MeecoService

    init(service: MeecoService = MeecoService()) {
        self.service = service
    }

    func load() async {
        guard state != .loading else { return }
        state = .loading
        do {
            loginForm = try await service.fetchLoginForm()
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

@MainActor
final class AttendanceViewModel: ObservableObject {
    enum LoadingState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var snapshot: MeecoAttendanceSnapshot?
    @Published private(set) var state: LoadingState = .idle

    private let service: MeecoService

    init(service: MeecoService = MeecoService()) {
        self.service = service
    }

    func load() async {
        guard state != .loading else { return }
        state = .loading
        do {
            snapshot = try await service.fetchAttendanceSnapshot()
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

@MainActor
final class NotificationCenterViewModel: ObservableObject {
    enum LoadingState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var snapshot: MeecoNotificationSnapshot?
    @Published private(set) var state: LoadingState = .idle

    private let service: MeecoService

    init(service: MeecoService = MeecoService()) {
        self.service = service
    }

    var unreadCount: Int {
        snapshot?.unreadCount ?? 0
    }

    func load(force: Bool = false) async {
        guard force || state != .loading else { return }
        state = .loading
        do {
            snapshot = try await service.fetchNotificationSnapshot()
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func markRead(_ notification: MeecoNotification) async {
        guard notification.isUnread, let url = notification.url else { return }
        applyReadState(for: notification.id)
        do {
            try await service.markNotificationRead(url: url)
            await load(force: true)
        } catch {
            await load(force: true)
        }
    }

    private func applyReadState(for id: String) {
        guard let currentSnapshot = snapshot else { return }
        var didUpdateUnread = false
        let notifications = currentSnapshot.notifications.map { notification in
            guard notification.id == id, notification.isUnread else { return notification }
            didUpdateUnread = true
            return MeecoNotification(
                id: notification.id,
                title: notification.title,
                body: notification.body,
                date: notification.date,
                url: notification.url,
                isUnread: false
            )
        }
        snapshot = MeecoNotificationSnapshot(
            unreadCount: didUpdateUnread ? max(0, currentSnapshot.unreadCount - 1) : currentSnapshot.unreadCount,
            notifications: notifications.sortedForDisplay,
            fetchedAt: Date()
        )
    }
}

struct NotificationCenterView: View {
    @EnvironmentObject private var authSession: MeecoAuthSession
    @EnvironmentObject private var viewModel: NotificationCenterViewModel
    @State private var webAction: MeecoWebAction?

    var body: some View {
        List {
            Section("알림") {
                switch authSession.status {
                case .unknown, .checking:
                    HStack {
                        ProgressView()
                        Text("로그인 상태 확인 중")
                    }
                case .loggedOut, .failed:
                    VStack(alignment: .leading, spacing: 10) {
                        Label("로그인이 필요합니다", systemImage: "bell.badge")
                            .font(.headline)
                        Text("댓글, 답글, 추천 등 내 알림은 미코 계정 로그인 후 확인할 수 있습니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        NavigationLink(destination: AccountSettingsView().hideRootTabBar()) {
                            Label("로그인", systemImage: "person.crop.circle.fill")
                        }
                    }
                    .padding(.vertical, 4)
                case .loggedIn:
                    notificationStatusContent
                }
            }

            if let snapshot = viewModel.snapshot, !snapshot.notifications.isEmpty {
                Section("최근 알림") {
                    ForEach(snapshot.notifications) { notification in
                        Button {
                            if let url = notification.url {
                                webAction = MeecoWebAction(title: "알림", url: url)
                                Task { await viewModel.markRead(notification) }
                            }
                        } label: {
                            NotificationRow(notification: notification)
                        }
                        .buttonStyle(.plain)
                        .disabled(notification.url == nil)
                    }
                }
            }
        }
        .navigationTitle("알림")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.load(force: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.state == .loading || !authSession.isLoggedIn)
                .accessibilityLabel("새로고침")
            }
        }
        .sheet(item: $webAction) { action in
            WebActionView(action: action)
        }
        .task {
            await authSession.verifySession()
            if authSession.isLoggedIn {
                await viewModel.load()
            }
        }
        .refreshable {
            if authSession.isLoggedIn {
                await viewModel.load(force: true)
            }
        }
    }

    @ViewBuilder
    private var notificationStatusContent: some View {
        if viewModel.snapshot == nil && (viewModel.state == .idle || viewModel.state == .loading) {
            HStack {
                ProgressView()
                Text("알림을 불러오는 중")
            }
        } else {
            switch viewModel.state {
            case .failed(let message):
                VStack(alignment: .leading, spacing: 10) {
                    Label("알림을 불러오지 못했습니다", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Label("다시 시도", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 4)
            default:
                if let snapshot = viewModel.snapshot {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(
                            snapshot.unreadCount > 0 ? "읽지 않은 알림 \(snapshot.unreadCount)개" : "새 알림 없음",
                            systemImage: snapshot.unreadCount > 0 ? "bell.badge.fill" : "bell"
                        )
                        .font(.headline)
                        .foregroundColor(snapshot.unreadCount > 0 ? .accentColor : .secondary)

                        Text("최근 업데이트 \(snapshot.fetchedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: MeecoNotification

    private var foregroundStyle: Color {
        notification.isUnread ? .primary : .secondary
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: notification.isUnread ? "bell.badge.fill" : "bell")
                .foregroundColor(notification.isUnread ? .accentColor : .secondary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title)
                        .font(.subheadline.weight(notification.isUnread ? .bold : .semibold))
                        .foregroundColor(foregroundStyle)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Text(notification.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if !notification.body.isEmpty {
                    Text(notification.body)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(notification.isUnread ? 1 : 0.68)
    }
}

struct AttendanceView: View {
    @EnvironmentObject private var authSession: MeecoAuthSession
    @StateObject private var viewModel = AttendanceViewModel()
    @State private var webAction: MeecoWebAction?

    private let attendanceURL = URL(string: "https://meeco.kr/attendance")!

    var body: some View {
        List {
            Section("출석") {
                switch authSession.status {
                case .unknown, .checking:
                    HStack {
                        ProgressView()
                        Text("로그인 상태 확인 중")
                    }
                case .loggedOut, .failed:
                    VStack(alignment: .leading, spacing: 10) {
                        Label("로그인이 필요합니다", systemImage: "person.crop.circle.badge.exclamationmark")
                            .font(.headline)
                        Text("출석 상태 확인과 출석 체크는 미코 계정 로그인 후 사용할 수 있습니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        NavigationLink(destination: AccountSettingsView().hideRootTabBar()) {
                            Label("로그인", systemImage: "person.crop.circle.fill")
                        }
                    }
                    .padding(.vertical, 4)
                case .loggedIn:
                    attendanceStatusContent
                }
            }

            if let snapshot = viewModel.snapshot, !snapshot.records.isEmpty {
                Section("최근 출석") {
                    ForEach(snapshot.records.prefix(20)) { record in
                        AttendanceRecordRow(record: record)
                    }
                }
            }
        }
        .navigationTitle("출석부")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.state == .loading || !authSession.isLoggedIn)
                .accessibilityLabel("새로고침")
            }
        }
        .sheet(item: $webAction) { action in
            WebActionView(action: action)
        }
        .task {
            await authSession.verifySession()
            if authSession.isLoggedIn {
                await viewModel.load()
            }
        }
        .refreshable {
            if authSession.isLoggedIn {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var attendanceStatusContent: some View {
        if viewModel.snapshot == nil && (viewModel.state == .idle || viewModel.state == .loading) {
            HStack {
                ProgressView()
                Text("출석 정보를 불러오는 중")
            }
        } else {
            switch viewModel.state {
        case .failed(let message):
            VStack(alignment: .leading, spacing: 10) {
                Label("출석 정보를 불러오지 못했습니다", systemImage: "exclamationmark.triangle")
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Label("다시 시도", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 4)
        default:
            if let snapshot = viewModel.snapshot {
                VStack(alignment: .leading, spacing: 12) {
                    Label(
                        snapshot.statusMessage,
                        systemImage: snapshot.isCheckedInToday ? "checkmark.seal.fill" : "calendar.badge.checkmark"
                    )
                    .font(.headline)
                    .foregroundColor(snapshot.isCheckedInToday ? .green : .accentColor)

                    if let cumulativeAttendanceDays = snapshot.cumulativeAttendanceDays {
                        Label("누적 출석 \(cumulativeAttendanceDays)일", systemImage: "calendar")
                            .font(.subheadline.weight(.semibold))
                    }

                    if !snapshot.attendedDates.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("이전 출석일")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            Text(snapshot.attendedDates.prefix(12).joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                    }

                    Text("최근 업데이트 \(snapshot.fetchedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button {
                        webAction = MeecoWebAction(title: "출석 체크", url: attendanceURL)
                    } label: {
                        Label(snapshot.isCheckedInToday ? "출석부 열기" : "출석 체크", systemImage: "safari")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 4)
            }
            }
        }
    }
}

struct AttendanceRecordRow: View {
    let record: MeecoAttendanceRecord

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let rank = record.rank {
                Text("\(rank)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.accentColor)
                    .clipShape(Circle())
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .frame(width: 24, height: 24)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.nickname)
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 8)
                    Text(record.time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !record.message.isEmpty {
                    Text(record.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            if let points = record.points {
                Text("+\(points)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.green)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }
}

struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authSession: MeecoAuthSession
    @State private var webAction: MeecoWebAction?

    var body: some View {
        NavigationView {
            List {
                Section("계정") {
                    switch authSession.status {
                    case .unknown, .checking:
                        HStack {
                            ProgressView()
                            Text(authSession.statusText)
                        }
                    case .failed(let message):
                        VStack(alignment: .leading, spacing: 8) {
                            Text("로그인 상태를 확인하지 못했습니다")
                                .font(.headline)
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button("다시 시도") {
                                Task { await authSession.verifySession() }
                            }
                        }
                        .padding(.vertical, 4)
                    case .loggedIn:
                        Label(authSession.statusText, systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Button(role: .destructive) {
                            Task { await authSession.logout() }
                        } label: {
                            Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    case .loggedOut:
                        LoginCredentialFormView()
                    }
                }

                if !authSession.isLoggedIn, let loginForm = authSession.loginForm {
                    Section("계정 도움말") {
                        if let signUpURL = loginForm.signUpURL {
                            Button {
                                webAction = MeecoWebAction(title: "회원가입", url: signUpURL)
                            } label: {
                                Label("회원가입", systemImage: "person.badge.plus")
                            }
                        }

                        if let findAccountURL = loginForm.findAccountURL {
                            Button {
                                webAction = MeecoWebAction(title: "ID/PW 찾기", url: findAccountURL)
                            } label: {
                                Label("ID/PW 찾기", systemImage: "questionmark.circle")
                            }
                        }
                    }
                }
            }
            .navigationTitle("설정")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $webAction) { action in
            WebActionView(action: action)
        }
        .task {
            await authSession.verifySession()
            await authSession.prepareLoginForm()
        }
    }
}

struct LoginCredentialFormView: View {
    @EnvironmentObject private var authSession: MeecoAuthSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("아이디", text: $authSession.userID)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            SecureField("비밀번호", text: $authSession.password)

            Toggle("로그인 유지", isOn: $authSession.keepSigned)

            Button {
                Task { await authSession.login() }
            } label: {
                Label("로그인", systemImage: "person.crop.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(authSession.userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || authSession.password.isEmpty)
        }
        .padding(.vertical, 4)
    }
}

#if os(macOS)
struct WebActionView: View {
    let action: MeecoWebAction

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(action.title)
                    .font(.headline)
                Spacer()
                Button("닫기") {
                    dismiss()
                }
            }
            .padding()

            WebArticleView(url: action.url)
        }
        .frame(minWidth: 720, minHeight: 640)
    }
}

struct WebArticleView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if nsView.url != url {
            nsView.load(URLRequest(url: url))
        }
    }
}
#else
struct WebActionView: View {
    let action: MeecoWebAction

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            WebArticleView(url: action.url)
                .navigationTitle(action.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("닫기") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct WebArticleView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
}
#endif

struct MeecoService {
    typealias BoardSnapshotFetcher = (MeecoBoard, Int, MeecoBoardCategory?) async throws -> MeecoBoardSnapshot

    enum ServiceError: LocalizedError {
        case invalidResponse
        case emptyResult
        case loginFailed

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "미코 서버 응답을 확인하지 못했습니다."
            case .emptyResult:
                return "파싱된 내용이 없습니다."
            case .loginFailed:
                return "로그인에 실패했습니다. 아이디와 비밀번호를 확인해 주세요."
            }
        }
    }

    static let loginFormURL = URL(string: "https://meeco.kr/index.php?act=dispMemberLoginForm")!
    static let attendanceURL = URL(string: "https://meeco.kr/attendance")!
    static let notificationURL = URL(string: "https://meeco.kr/index.php?act=dispNcenterliteNotifyList")!

    private let parser = MeecoHTMLParser()
    private let boardSnapshotFetcher: BoardSnapshotFetcher?

    init(boardSnapshotFetcher: BoardSnapshotFetcher? = nil) {
        self.boardSnapshotFetcher = boardSnapshotFetcher
    }

    func fetchBoardSnapshot(for board: MeecoBoard, page: Int = 1, category: MeecoBoardCategory? = nil) async throws -> MeecoBoardSnapshot {
        if let boardSnapshotFetcher {
            return try await boardSnapshotFetcher(board, page, category)
        }

        let url = board.pageURL(page, category: category)
        let html = try await fetchHTML(from: cacheBypassedURL(from: url))
        let posts = parser.posts(
            from: html,
            baseURL: url,
            allowedBoardPaths: board.allowedBoardPaths,
            category: category
        )

        guard !posts.isEmpty else { throw ServiceError.emptyResult }
        return MeecoBoardSnapshot(posts: posts, page: page, sourceFingerprint: html.hashValue, fetchedAt: Date())
    }

    func fetchPostDetail(for post: MeecoPost) async throws -> MeecoPostDetail {
        let html = try await fetchHTML(from: post.url)
        return parser.postDetail(from: html, fallbackPost: post)
    }

    func fetchAttendanceSnapshot() async throws -> MeecoAttendanceSnapshot {
        await syncWebViewCookiesToSharedStorage()
        let html = try await fetchHTML(from: cacheBypassedURL(from: Self.attendanceURL), validatesStatus: false)
        return parser.attendanceSnapshot(from: html)
    }

    func fetchNotificationSnapshot() async throws -> MeecoNotificationSnapshot {
        await syncWebViewCookiesToSharedStorage()
        let html = try await fetchHTML(from: cacheBypassedURL(from: Self.notificationURL), validatesStatus: false)
        return parser.notificationSnapshot(from: html, baseURL: Self.notificationURL)
    }

    func markNotificationRead(url: URL) async throws {
        await syncWebViewCookiesToSharedStorage()
        _ = try await fetchHTML(from: url, validatesStatus: false)
    }

    func fetchLoginForm() async throws -> MeecoLoginForm {
        let html = try await fetchHTML(from: Self.loginFormURL)
        guard let loginForm = parser.loginForm(from: html, baseURL: Self.loginFormURL) else {
            throw ServiceError.emptyResult
        }

        return loginForm
    }

    func fetchAuthStatus() async throws -> MeecoAuthStatus {
        if let cookieStatus = authStatusFromCookies() {
            return cookieStatus
        }
        let html = try await fetchHTML(from: Self.loginFormURL, validatesStatus: false)
        let status = parser.authStatus(from: html)
        return status.isLoggedIn ? status : authStatusFromCookies() ?? status
    }

    func login(credentials: MeecoLoginCredentials, form: MeecoLoginForm) async throws -> MeecoAuthStatus {
        var fields = form.hiddenFields
        fields[form.userIDField] = credentials.userID
        fields[form.passwordField] = credentials.password
        if let keepSignedField = form.keepSignedField {
            if credentials.keepSigned {
                fields[keepSignedField] = form.keepSignedDefaultValue ?? "Y"
            } else {
                fields.removeValue(forKey: keepSignedField)
            }
        }

        var requestURL = form.actionURL
        var request = URLRequest(url: requestURL)
        request.httpMethod = form.method == "GET" ? "GET" : "POST"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 20
        request.httpShouldHandleCookies = true
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue(Self.loginFormURL.absoluteString, forHTTPHeaderField: "Referer")
        request.setValue("https://meeco.kr", forHTTPHeaderField: "Origin")

        let encodedFields = formURLEncoded(fields)
        if request.httpMethod == "GET" {
            var components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)
            let existingQuery = components?.percentEncodedQuery
            components?.percentEncodedQuery = [existingQuery, encodedFields].compactMap { $0?.nonEmpty }.joined(separator: "&")
            requestURL = components?.url ?? requestURL
            request.url = requestURL
        } else {
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = encodedFields.data(using: .utf8)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        await syncCookiesToWebViewStore(from: response, for: requestURL)
        if let cookieStatus = authStatusFromCookies(), cookieStatus.isLoggedIn {
            return cookieStatus
        }

        guard let html = decodeHTML(data) else {
            throw ServiceError.invalidResponse
        }

        let status = parser.authStatus(from: html)
        if status.isLoggedIn {
            return status
        }

        let verifiedStatus = try await fetchAuthStatus()
        guard verifiedStatus.isLoggedIn else {
            throw ServiceError.loginFailed
        }
        return verifiedStatus
    }

    func clearSessionCookies() async {
        let storage = HTTPCookieStorage.shared
        storage.cookies?
            .filter { $0.domain.contains("meeco.kr") }
            .forEach(storage.deleteCookie)

        await MainActor.run {
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                let meecoCookies = cookies.filter { $0.domain.contains("meeco.kr") }
                for cookie in meecoCookies {
                    WKWebsiteDataStore.default().httpCookieStore.delete(cookie)
                }
            }
        }
    }

    private func cacheBypassedURL(from url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "_meeco_refresh" }
        queryItems.append(URLQueryItem(name: "_meeco_refresh", value: UUID().uuidString))
        components.queryItems = queryItems
        return components.url ?? url
    }

    private func fetchHTML(from url: URL, validatesStatus: Bool = true) async throws -> String {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 20
        request.httpShouldHandleCookies = true
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("no-cache, no-store, max-age=0", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.setValue("0", forHTTPHeaderField: "Expires")

        let (data, response) = try await URLSession.shared.data(for: request)
        if validatesStatus {
            try validateHTTPResponse(response)
        }
        guard let html = decodeHTML(data) else {
            throw ServiceError.invalidResponse
        }

        return html
    }

    private func syncWebViewCookiesToSharedStorage() async {
        let cookies = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                    continuation.resume(returning: cookies)
                }
            }
        }

        cookies
            .filter { $0.domain.contains("meeco.kr") }
            .forEach { HTTPCookieStorage.shared.setCookie($0) }
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<400).contains(httpResponse.statusCode) else {
            throw ServiceError.invalidResponse
        }
    }

    private func decodeHTML(_ data: Data) -> String? {
        String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.EUC_KR.rawValue))))
    }

    private func formURLEncoded(_ fields: [String: String]) -> String {
        fields
            .sorted { $0.key < $1.key }
            .map { key, value in
                "\(urlEncodedFormComponent(key))=\(urlEncodedFormComponent(value))"
            }
            .joined(separator: "&")
    }

    private func urlEncodedFormComponent(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=?")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    private func syncCookiesToWebViewStore(from response: URLResponse, for url: URL) async {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        let responseCookies = HTTPCookie.cookies(withResponseHeaderFields: httpResponse.allHeaderFields as? [String: String] ?? [:], for: url)
        let storedCookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
        let cookies = responseCookies + storedCookies
        guard !cookies.isEmpty else { return }

        await MainActor.run {
            for cookie in cookies {
                WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie)
            }
        }
    }

    private func authStatusFromCookies() -> MeecoAuthStatus? {
        guard let cookie = HTTPCookieStorage.shared.cookies?
            .first(where: { $0.domain.contains("meeco.kr") && $0.name == "rx_login_status" }) else {
            return nil
        }

        let value = cookie.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.lowercased() != "none" else {
            return MeecoAuthStatus(isLoggedIn: false, displayName: nil)
        }

        return MeecoAuthStatus(isLoggedIn: true, displayName: nil)
    }
}

struct MeecoHTMLParser {
    private let ignoredTitles: Set<String> = [
        "로그인",
        "회원가입",
        "목록",
        "쓰기",
        "새 글 쓰기",
        "전체",
        "검색",
        "이전",
        "다음"
    ]

    func posts(from html: String, baseURL: URL, allowedBoardPaths: Set<String>?, category: MeecoBoardCategory? = nil) -> [MeecoPost] {
        let rows = html.matches(pattern: #"<tr\b[^>]*>(.*?)</tr>"#, options: [.caseInsensitive, .dotMatchesLineSeparators])
        let rowPosts = rows.compactMap {
            post(
                fromRowHTML: $0[1],
                baseURL: baseURL,
                allowedBoardPaths: allowedBoardPaths,
                requiredCategory: category
            )
        }

        if !rowPosts.isEmpty {
            return unique(rowPosts)
        }

        let listItems = html.matches(pattern: #"<li\b[^>]*>(.*?)</li>"#, options: [.caseInsensitive, .dotMatchesLineSeparators])
        let listPosts = listItems.compactMap {
            post(
                fromRowHTML: $0[1],
                baseURL: baseURL,
                allowedBoardPaths: allowedBoardPaths,
                requiredCategory: category
            )
        }

        if !listPosts.isEmpty {
            return unique(listPosts)
        }

        return unique(postsFromAnchors(
            html: html,
            baseURL: baseURL,
            allowedBoardPaths: allowedBoardPaths,
            requiredCategory: category
        ))
    }

    func postDetail(from html: String, fallbackPost: MeecoPost) -> MeecoPostDetail {
        let title = bestTitle(from: html, fallbackTitle: fallbackPost.title)
        let bodyHTML = firstContentBlock(in: html) ?? ""
        let body = bodyWithoutLeadingTitle(bodyHTML.displayText.nonEmpty ?? html.displayText, title: title)
        let bodyBlocks = postBodyBlocks(from: bodyHTML, title: title, baseURL: fallbackPost.url)
        let media = mediaItems(from: bodyHTML, baseURL: fallbackPost.url)
        let comments = comments(from: html, baseURL: fallbackPost.url, postAuthorNickname: fallbackPost.nickname)
        let dealInfo = fallbackPost.boardPath == "Price"
            ? priceDealInfo(from: html, bodyHTML: bodyHTML, baseURL: fallbackPost.url, fallbackTitle: title)
            : nil

        return MeecoPostDetail(
            title: title,
            nickname: fallbackPost.nickname,
            date: fallbackPost.date,
            body: body,
            bodyBlocks: bodyBlocks,
            media: media,
            comments: comments,
            dealInfo: dealInfo
        )
    }

    func attendanceSnapshot(from html: String) -> MeecoAttendanceSnapshot {
        let plainText = html.plainHTMLText
        let isCheckedInToday = attendanceCheckedIn(from: plainText)
        let records = attendanceRecords(from: html)
        return MeecoAttendanceSnapshot(
            statusMessage: attendanceStatusMessage(from: plainText, isCheckedInToday: isCheckedInToday),
            isCheckedInToday: isCheckedInToday,
            cumulativeAttendanceDays: cumulativeAttendanceDays(from: plainText),
            attendedDates: attendedDates(from: plainText),
            records: records,
            fetchedAt: Date()
        )
    }

    func notificationSnapshot(from html: String, baseURL: URL) -> MeecoNotificationSnapshot {
        let notifications = notificationItems(from: html, baseURL: baseURL).sortedForDisplay
        let parsedUnreadCount = unreadNotificationCount(from: html) ?? notifications.filter(\.isUnread).count
        let unreadCount = notifications.isEmpty ? 0 : min(parsedUnreadCount, notifications.count)
        return MeecoNotificationSnapshot(
            unreadCount: unreadCount,
            notifications: notifications,
            fetchedAt: Date()
        )
    }

    private func priceDealInfo(from html: String, bodyHTML: String, baseURL: URL, fallbackTitle: String) -> MeecoDealInfo? {
        let rows = priceExtraRows(from: html)
        let explicitStatus = rows
            .first { row in row.label.contains("진행") || row.label.contains("상태") || row.label.localizedCaseInsensitiveContains("status") }
            .map(\.value.normalizedDealStatus)
            .flatMap { $0 }
        let inferredStatus = explicitStatus ?? inferredDealStatus(title: fallbackTitle, bodyHTML: bodyHTML)
        let links = priceDealLinks(from: rows, bodyHTML: bodyHTML, baseURL: baseURL)

        guard inferredStatus != nil || !links.isEmpty else { return nil }
        return MeecoDealInfo(status: inferredStatus, links: links)
    }

    private func unreadNotificationCount(from html: String) -> Int? {
        let text = html.plainHTMLText
        let patterns = [
            #"읽지\s*않은\s*알림\s*(\d+)"#,
            #"새\s*알림\s*(\d+)"#,
            #"unread\s*(\d+)"#
        ]

        return patterns
            .lazy
            .compactMap { text.firstMatch(pattern: $0, options: [.caseInsensitive]).flatMap(Int.init) }
            .first
    }

    private func notificationItems(from html: String, baseURL: URL) -> [MeecoNotification] {
        let listItems = html.matches(
            pattern: #"<li\b([^>]*)>(.*?)</li>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        .compactMap { match -> MeecoNotification? in
            guard match.count > 2 else { return nil }
            return notificationItem(attributes: match[1], bodyHTML: match[2], baseURL: baseURL)
        }

        if !listItems.isEmpty {
            return uniqueNotifications(listItems)
        }

        let tableRows = html.matches(
            pattern: #"<tr\b([^>]*)>(.*?)</tr>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        .compactMap { match -> MeecoNotification? in
            guard match.count > 2 else { return nil }
            return notificationItem(attributes: match[1], bodyHTML: match[2], baseURL: baseURL)
        }

        return uniqueNotifications(tableRows)
    }

    private func notificationItem(attributes: String, bodyHTML: String, baseURL: URL) -> MeecoNotification? {
        let plainText = bodyHTML.plainHTMLText
        guard !plainText.isEmpty else { return nil }

        let hasNotificationMarker = attributes.localizedCaseInsensitiveContains("notify")
            || attributes.localizedCaseInsensitiveContains("ncenter")
            || attributes.localizedCaseInsensitiveContains("unread")
            || bodyHTML.localizedCaseInsensitiveContains("procNcenterliteRedirect")
            || bodyHTML.localizedCaseInsensitiveContains("ncenterlite")
            || bodyHTML.localizedCaseInsensitiveContains("notify")
            || bodyHTML.localizedCaseInsensitiveContains("is_read")

        guard hasNotificationMarker else {
            return nil
        }

        let link = bodyHTML.matches(
            pattern: #"<a\s+([^>]*\bhref\s*=\s*[\"']([^\"']+)[\"'][^>]*)>(.*?)</a>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        .compactMap { match -> (url: URL, title: String)? in
            guard match.count > 3,
                  let url = URL(string: match[2].htmlDecoded, relativeTo: baseURL)?.absoluteURL else {
                return nil
            }
            return (url, match[3].plainHTMLText)
        }
        .first

        let date = plainText.firstMatch(
            pattern: #"(20\d{2}[./-]\d{1,2}[./-]\d{1,2}\.?\s*\d{0,2}:?\d{0,2}|\d{2}[./-]\d{1,2}[./-]\d{1,2}\.?\s*\d{0,2}:?\d{0,2}|\d{1,2}:\d{2}|방금\s*전|\d+\s*(?:분|시간|일)\s*전)"#
        ) ?? ""
        let title = link?.title.nonEmpty
            ?? plainText.components(separatedBy: date).first?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
            ?? "알림"
        let body = plainText
            .replacingOccurrences(of: title, with: "")
            .replacingOccurrences(of: date, with: "")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let unread = attributes.localizedCaseInsensitiveContains("unread")
            || attributes.firstMatch(pattern: #"class\s*=\s*["'][^"']*\bnew\b"#, options: [.caseInsensitive]) != nil
            || bodyHTML.firstMatch(pattern: #"class\s*=\s*["'][^"']*\bunread\b"#, options: [.caseInsensitive]) != nil
            || bodyHTML.firstMatch(pattern: #"class\s*=\s*["'][^"']*\bnew\b"#, options: [.caseInsensitive]) != nil
            || bodyHTML.localizedCaseInsensitiveContains("is_read\">N")

        return MeecoNotification(
            id: link?.url.absoluteString ?? plainText,
            title: title,
            body: body,
            date: date,
            url: link?.url,
            isUnread: unread
        )
    }

    private func uniqueNotifications(_ notifications: [MeecoNotification]) -> [MeecoNotification] {
        var seen = Set<String>()
        return notifications.filter { seen.insert($0.id).inserted }
    }

    private func attendanceCheckedIn(from text: String) -> Bool {
        let lowered = text.lowercased()
        return text.contains("출석완료")
            || text.contains("출석 완료")
            || text.contains("이미 출석")
            || text.contains("오늘 출석")
            || lowered.contains("checked")
            || lowered.contains("already")
    }

    private func attendanceStatusMessage(from text: String, isCheckedInToday: Bool) -> String {
        if isCheckedInToday {
            return "오늘 출석 완료"
        }

        if text.contains("로그인") && !text.contains("로그아웃") {
            return "로그인 후 출석할 수 있습니다"
        }

        return "오늘 출석 전"
    }

    private func cumulativeAttendanceDays(from text: String) -> Int? {
        let patterns = [
            #"누적\s*출석(?:일|일수)?\s*[:：]?\s*(\d+)\s*일"#,
            #"총\s*출석(?:일|일수)?\s*[:：]?\s*(\d+)\s*일"#,
            #"출석(?:일|일수)\s*[:：]?\s*(\d+)\s*일"#,
            #"(\d+)\s*일\s*(?:연속|누적)?\s*출석"#
        ]

        return patterns
            .lazy
            .compactMap { text.firstMatch(pattern: $0).flatMap(Int.init) }
            .first
    }

    private func attendedDates(from text: String) -> [String] {
        var seen = Set<String>()
        return text.matches(pattern: #"(20\d{2}[./-]\d{1,2}[./-]\d{1,2}|\d{2}[./-]\d{1,2}[./-]\d{1,2})"#)
            .compactMap { match in
                match.indices.contains(1) ? match[1] : nil
            }
            .filter { date in
                seen.insert(date).inserted
            }
    }

    private func attendanceRecords(from html: String) -> [MeecoAttendanceRecord] {
        let tableRows = html.matches(
            pattern: #"<tr\b[^>]*>(.*?)</tr>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        .compactMap { match -> MeecoAttendanceRecord? in
            guard match.count > 1 else { return nil }
            let cells = match[1].matches(
                pattern: #"<t[dh]\b[^>]*>(.*?)</t[dh]>"#,
                options: [.caseInsensitive, .dotMatchesLineSeparators]
            )
            .compactMap { $0.count > 1 ? $0[1].plainHTMLText.nonEmpty : nil }
            return attendanceRecord(from: cells)
        }

        if !tableRows.isEmpty {
            return tableRows
        }

        return html.matches(
            pattern: #"<li\b[^>]*>(.*?)</li>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        .compactMap { match -> MeecoAttendanceRecord? in
            guard match.count > 1 else { return nil }
            let fields = match[1].matches(
                pattern: #"<(?:span|div|time|strong|em)\b[^>]*>(.*?)</(?:span|div|time|strong|em)>"#,
                options: [.caseInsensitive, .dotMatchesLineSeparators]
            )
            .compactMap { $0.count > 1 ? $0[1].plainHTMLText.nonEmpty : nil }
            return attendanceRecord(from: fields.isEmpty ? [match[1].plainHTMLText] : fields)
        }
    }

    private func attendanceRecord(from fields: [String]) -> MeecoAttendanceRecord? {
        let cleanedFields = fields
            .map { $0.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard cleanedFields.count >= 2 else { return nil }
        guard cleanedFields.contains(where: { $0.isPostDate || $0.firstMatch(pattern: #"\d{1,2}:\d{2}"#) != nil }) else {
            return nil
        }

        let rank = cleanedFields.first.flatMap { Int($0) }
        let time = cleanedFields.first(where: { $0.isPostDate || $0.firstMatch(pattern: #"\d{1,2}:\d{2}"#) != nil }) ?? ""
        let points = cleanedFields
            .compactMap { field -> Int? in
                if let point = field.firstMatch(pattern: #"([+-]?\d+)\s*(?:포인트|point|pt|p)"#, options: [.caseInsensitive]) {
                    return Int(point.replacingOccurrences(of: "+", with: ""))
                }
                return nil
            }
            .first
        let nickname = cleanedFields.first { field in
            field != time
                && Int(field) == nil
                && field.firstMatch(pattern: #"([+-]?\d+\s*(?:포인트|point|pt|p))"#, options: [.caseInsensitive]) == nil
                && !field.localizedCaseInsensitiveContains("출석")
        } ?? ""
        let message = cleanedFields
            .filter { field in
                field != nickname
                    && field != time
                    && Int(field) == nil
                    && field.firstMatch(pattern: #"([+-]?\d+\s*(?:포인트|point|pt|p))"#, options: [.caseInsensitive]) == nil
            }
            .max { $0.count < $1.count } ?? ""

        guard !nickname.isEmpty else { return nil }
        return MeecoAttendanceRecord(
            rank: rank,
            nickname: nickname,
            message: message,
            time: time,
            points: points
        )
    }

    private func priceExtraRows(from html: String) -> [(label: String, value: String, valueHTML: String)] {
        guard let tableHTML = html.firstMatch(
            pattern: #"<div\b[^>]*class=[\"'][^\"']*atc-ex[^\"']*[\"'][^>]*>.*?<table\b[^>]*>(.*?)</table>"#,
            group: 1,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return []
        }

        return tableHTML.matches(pattern: #"<tr\b[^>]*>(.*?)</tr>"#, options: [.caseInsensitive, .dotMatchesLineSeparators])
            .compactMap { match -> (label: String, value: String, valueHTML: String)? in
                guard match.count > 1 else { return nil }
                let rowHTML = match[1]
                let cells = rowHTML.matches(pattern: #"<t[dh]\b[^>]*>(.*?)</t[dh]>"#, options: [.caseInsensitive, .dotMatchesLineSeparators])
                guard cells.count >= 2 else { return nil }
                let label = cells[0][1].plainHTMLText
                let valueHTML = cells.dropFirst().map { $0[1] }.joined(separator: " ")
                let value = valueHTML.plainHTMLText
                guard !label.isEmpty || !value.isEmpty else { return nil }
                return (label, value, valueHTML)
            }
    }

    private func inferredDealStatus(title: String, bodyHTML: String) -> String? {
        let combined = [title, bodyHTML.plainHTMLText]
            .joined(separator: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        if combined.contains("종료") || combined.localizedCaseInsensitiveContains("expired") || combined.localizedCaseInsensitiveContains("sold out") {
            return "종료"
        }
        return "진행 중"
    }

    private func priceDealLinks(from rows: [(label: String, value: String, valueHTML: String)], bodyHTML: String, baseURL: URL) -> [MeecoDealLink] {
        let rowLinkHTML = rows
            .filter { row in
                row.label.contains("링크")
                    || row.label.contains("구매")
                    || row.label.contains("판매")
                    || row.label.localizedCaseInsensitiveContains("url")
                    || row.label.localizedCaseInsensitiveContains("link")
            }
            .map(\.valueHTML)
            .joined(separator: " ")
        let linkHTML = [rowLinkHTML, bodyHTML].joined(separator: " ")
        var seen = Set<URL>()

        return linkHTML.matches(
            pattern: #"<a\s+([^>]*\bhref\s*=\s*[\"']([^\"']+)[\"'][^>]*)>(.*?)</a>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        .compactMap { match -> MeecoDealLink? in
            guard match.count > 3,
                  let url = URL(string: match[2].htmlDecoded, relativeTo: baseURL)?.absoluteURL,
                  isExternalDealURL(url),
                  seen.insert(url).inserted else {
                return nil
            }
            let title = match[3].plainHTMLText.nonEmpty ?? url.host ?? "구매 링크"
            return MeecoDealLink(
                id: url,
                title: title,
                url: url,
                isRevenueGenerating: isRevenueGeneratingDealLink(url: url, attributes: match[1])
            )
        }
    }

    private func isExternalDealURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased(), !host.contains("meeco.kr") else { return false }
        return !shouldUseImageURL(url) && !shouldUseVideoURL(url)
    }

    private func isRevenueGeneratingDealLink(url: URL, attributes: String) -> Bool {
        let host = url.host?.lowercased() ?? ""
        let loweredAttributes = attributes.lowercased()
        return loweredAttributes.contains("dis_func_link")
            || loweredAttributes.contains("af_srl")
            || host.contains("linkprice.com")
            || host.contains("coupa.ng")
            || host.contains("partners.coupang.com")
            || host.contains("link.coupang.com")
    }

    func loginForm(from html: String, baseURL: URL) -> MeecoLoginForm? {
        let forms = html.matches(
            pattern: #"<form\b([^>]*)>(.*?)</form>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )

        guard let form = forms.first(where: { match in
            match.count > 2 && match[2].localizedCaseInsensitiveContains("procMemberLogin")
        }) else {
            return nil
        }

        let formAttributes = form[1]
        let formHTML = form[2]
        let action = attributeValue(named: "action", in: formAttributes) ?? "/"
        let method = (attributeValue(named: "method", in: formAttributes) ?? "GET").uppercased()

        guard let actionURL = URL(string: action, relativeTo: baseURL)?.absoluteURL,
              let userIDField = inputName(in: formHTML, matching: "user_id"),
              let passwordField = inputName(in: formHTML, matching: "password") else {
            return nil
        }

        let keepSignedField = inputName(in: formHTML, matching: "keep_signed")

        return MeecoLoginForm(
            actionURL: actionURL,
            method: method,
            userIDField: userIDField,
            passwordField: passwordField,
            keepSignedField: keepSignedField,
            keepSignedDefaultValue: inputValue(in: formHTML, named: keepSignedField),
            validatorID: inputValue(in: formHTML, named: "xe_validator_id"),
            signUpURL: firstLinkURL(in: html, containing: "dispMemberSignUpForm", baseURL: baseURL),
            findAccountURL: firstLinkURL(in: html, containing: "dispMemberFindAccount", baseURL: baseURL),
            hiddenFields: inputValues(in: formHTML, type: "hidden")
        )
    }

    func authStatus(from html: String) -> MeecoAuthStatus {
        let hasLoginForm = loginForm(from: html, baseURL: MeecoService.loginFormURL) != nil
        if hasConcreteLogoutAction(in: html)
            || (!hasLoginForm && hasMemberInfoLink(in: html)) {
            return MeecoAuthStatus(isLoggedIn: true, displayName: loggedInDisplayName(from: html))
        }

        if hasLoginForm {
            return MeecoAuthStatus(isLoggedIn: false, displayName: nil)
        }

        return MeecoAuthStatus(isLoggedIn: false, displayName: nil)
    }

    private func hasConcreteLogoutAction(in html: String) -> Bool {
        html.matches(
            pattern: #"(?:href|action)\s*=\s*["'][^"']*(?:procMemberLogout|dispMemberLogout)[^"']*["']"#,
            options: [.caseInsensitive]
        ).isEmpty == false
    }

    private func hasMemberInfoLink(in html: String) -> Bool {
        html.matches(
            pattern: #"(?:href|action)\s*=\s*["'][^"']*dispMemberInfo[^"']*["']"#,
            options: [.caseInsensitive]
        ).isEmpty == false
    }

    private func loggedInDisplayName(from html: String) -> String? {
        let candidates = [
            html.firstMatch(pattern: #"<a\b[^>]*href=["'][^"']*dispMemberInfo[^"']*["'][^>]*>(.*?)</a>"#, group: 1, options: [.caseInsensitive, .dotMatchesLineSeparators]),
            html.firstMatch(pattern: #"<span\b[^>]*class=["'][^"']*(?:nickname|member)[^"']*["'][^>]*>(.*?)</span>"#, group: 1, options: [.caseInsensitive, .dotMatchesLineSeparators])
        ]

        return candidates
            .compactMap { $0?.plainHTMLText.nonEmpty }
            .first
    }

    private func post(fromRowHTML rowHTML: String, baseURL: URL, allowedBoardPaths: Set<String>?, requiredCategory: MeecoBoardCategory?) -> MeecoPost? {
        guard let anchor = articleAnchors(in: rowHTML, baseURL: baseURL, allowedBoardPaths: allowedBoardPaths).first else {
            return nil
        }
        guard postMatchesCategory(rowHTML: rowHTML, anchor: anchor, requiredCategory: requiredCategory) else {
            return nil
        }

        let cells = rowHTML.matches(pattern: #"<t[dh]\b[^>]*>(.*?)</t[dh]>"#, options: [.caseInsensitive, .dotMatchesLineSeparators])
            .map { $0[1].plainHTMLText }
            .filter { !$0.isEmpty }
        let rowText = rowHTML.plainHTMLText
        let title = anchor.title.nonEmpty ?? titleFromCells(cells, excluding: anchor.documentID) ?? rowText
        guard shouldUseTitle(title) else { return nil }

        let date = inferDate(from: cells, rowHTML: rowHTML, rowText: rowText, title: title)
        let nickname = inferNickname(from: cells, rowHTML: rowHTML, rowText: rowText, title: title, date: date)
        let commentCount = inferCommentCount(from: rowHTML, title: title)
        let upvoteCount = inferPostUpvoteCount(from: rowHTML, cells: cells, title: title, date: date, nickname: nickname)
        let loweredRow = rowText.lowercased()
        let categoryID = anchor.categoryID ?? rowCategoryID(rowHTML)
        let category = rowCategoryTitle(rowHTML)
            ?? categoryLinkTitle(rowHTML: rowHTML, categoryID: categoryID)
            ?? inferCategory(from: cells, title: title)
            ?? categoryTitle(forCategoryID: categoryID)

        return MeecoPost(
            id: anchor.url,
            documentID: anchor.documentID,
            title: title,
            nickname: nickname,
            date: date,
            url: anchor.url,
            boardPath: anchor.boardPath,
            category: category,
            commentCount: commentCount,
            upvoteCount: upvoteCount,
            isNotice: isNoticeRow(rowHTML),
            isHot: loweredRow.contains("핫글") || loweredRow.contains("hot"),
            categoryColorHex: categoryColorHex(from: rowHTML, category: category, categoryID: categoryID),
            thumbnailURL: thumbnailURL(from: rowHTML, baseURL: baseURL)
        )
    }

    private func postsFromAnchors(html: String, baseURL: URL, allowedBoardPaths: Set<String>?, requiredCategory: MeecoBoardCategory?) -> [MeecoPost] {
        let requiredCategoryID = requiredCategory?.categoryID
        return articleAnchors(in: html, baseURL: baseURL, allowedBoardPaths: allowedBoardPaths).compactMap { anchor -> MeecoPost? in
            guard shouldUseTitle(anchor.title) else { return nil }
            if let requiredCategoryID, anchor.categoryID != requiredCategoryID {
                return nil
            }
            return MeecoPost(
                id: anchor.url,
                documentID: anchor.documentID,
                title: anchor.title,
                nickname: "",
                date: "",
                url: anchor.url,
                boardPath: anchor.boardPath,
                category: categoryTitle(forCategoryID: anchor.categoryID),
                commentCount: nil,
                upvoteCount: 0,
                isNotice: false,
                isHot: false,
                categoryColorHex: categoryColorHex(forCategoryID: anchor.categoryID),
                thumbnailURL: nil
            )
        }
    }

    private func articleAnchors(in html: String, baseURL: URL, allowedBoardPaths: Set<String>?) -> [ArticleAnchor] {
        let matches = html.matches(
            pattern: #"<a\s+([^>]*\bhref\s*=\s*[\"']([^\"']+)[\"'][^>]*)>(.*?)</a>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )

        let anchors = matches.compactMap { match -> ArticleAnchor? in
            let attributes = match[1]
            let href = match[2].htmlDecoded
            let title = match[3].plainHTMLText.nonEmpty ?? attributeValue(named: "title", in: attributes)?.plainHTMLText ?? ""
            guard let url = URL(string: href, relativeTo: baseURL)?.absoluteURL,
                  url.fragment == nil,
                  let info = articleInfo(from: url, allowedBoardPaths: allowedBoardPaths) else {
                return nil
            }

            let isTitleLink = attributes.localizedCaseInsensitiveContains("title_a")
            guard isTitleLink || shouldUseTitle(title) else {
                return nil
            }

            return ArticleAnchor(
                url: url,
                title: title,
                boardPath: info.boardPath,
                documentID: info.documentID,
                categoryID: categoryID(from: url),
                isTitleLink: isTitleLink
            )
        }

        return anchors.sorted { lhs, rhs in
            if lhs.isTitleLink != rhs.isTitleLink {
                return lhs.isTitleLink
            }

            return lhs.title.count > rhs.title.count
        }
    }

    private func articleInfo(from url: URL, allowedBoardPaths: Set<String>?) -> (boardPath: String, documentID: String)? {
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count == 2,
              let boardPath = components.first,
              let documentID = components.last?.components(separatedBy: "#").first,
              documentID.allSatisfy(\.isNumber) else {
            return nil
        }

        if let allowedBoardPaths, !allowedBoardPaths.contains(boardPath) {
            return nil
        }

        return (boardPath, documentID)
    }

    private func postMatchesCategory(rowHTML: String, anchor: ArticleAnchor, requiredCategory: MeecoBoardCategory?) -> Bool {
        guard let requiredCategoryID = requiredCategory?.categoryID else { return true }
        let categoryMatches = anchor.categoryID == requiredCategoryID
            || rowHTML.localizedCaseInsensitiveContains("/category/\(requiredCategoryID)")
            || rowHTML.localizedCaseInsensitiveContains("category=\(requiredCategoryID)")

        guard categoryMatches else { return false }

        if requiredCategoryID == "23941775" {
            return isNoticeRow(rowHTML)
        }

        let isPromotedRow = rowHTML.localizedCaseInsensitiveContains("hot_text")
            || rowHTML.localizedCaseInsensitiveContains("notice_text")
        if isPromotedRow {
            guard let requiredCategoryTitle = requiredCategory?.title else { return false }
            return rowCategoryTitle(rowHTML) == requiredCategoryTitle
                || categoryLinkTitle(rowHTML: rowHTML, categoryID: requiredCategoryID) == requiredCategoryTitle
        }

        if rowHTML.localizedCaseInsensitiveContains("list_ctg"),
           let requiredCategoryTitle = requiredCategory?.title {
            return rowCategoryTitle(rowHTML) == requiredCategoryTitle
        }

        return true
    }

    private func isNoticeRow(_ rowHTML: String) -> Bool {
        let rowText = rowHTML.plainHTMLText
        return rowHTML.localizedCaseInsensitiveContains("notice_text")
            || rowHTML.localizedCaseInsensitiveContains("list_ctg")
                && rowText.components(separatedBy: .whitespacesAndNewlines).contains("공지")
    }

    private func rowCategoryTitle(_ rowHTML: String) -> String? {
        rowHTML.firstMatch(
            pattern: #"<span\b[^>]*class=[\"'][^\"']*list_ctg[^\"']*[\"'][^>]*>(.*?)</span>"#,
            group: 1,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )?.plainHTMLText
    }

    private func rowCategoryID(_ rowHTML: String) -> String? {
        rowHTML.firstMatch(
            pattern: #"/category/(\d+)"#,
            options: [.caseInsensitive]
        ) ?? rowHTML.firstMatch(
            pattern: #"category=(\d+)"#,
            options: [.caseInsensitive]
        )
    }

    private func categoryLinkTitle(rowHTML: String, categoryID: String?) -> String? {
        guard let categoryID else { return nil }
        return rowHTML.firstMatch(
            pattern: #"<a\b[^>]*href=[\"'][^\"']*/category/\#(categoryID)(?:[?/#][^\"']*)?[\"'][^>]*>(.*?)</a>"#,
            group: 1,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )?.plainHTMLText
    }

    private func categoryID(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "category" })?
            .value
    }

    private func attributeValue(named name: String, in attributes: String) -> String? {
        attributes.firstMatch(
            pattern: #"\#(name)\s*=\s*[\"']([^\"']+)[\"']"#,
            group: 1,
            options: [.caseInsensitive]
        )?.htmlDecoded
    }

    private func inputName(in html: String, matching expectedName: String) -> String? {
        html.matches(pattern: #"<input\b([^>]*)>"#, options: [.caseInsensitive])
            .compactMap { match -> String? in
                guard match.count > 1 else { return nil }
                let name = attributeValue(named: "name", in: match[1])
                return name?.caseInsensitiveCompare(expectedName) == .orderedSame ? name : nil
            }
            .first
    }

    private func inputValue(in html: String, named name: String?) -> String? {
        guard let name else { return nil }
        return html.matches(pattern: #"<input\b([^>]*)>"#, options: [.caseInsensitive])
            .compactMap { match -> String? in
                guard match.count > 1,
                      attributeValue(named: "name", in: match[1])?.caseInsensitiveCompare(name) == .orderedSame else {
                    return nil
                }
                return attributeValue(named: "value", in: match[1])
            }
            .first
    }

    private func inputValues(in html: String, type expectedType: String) -> [String: String] {
        html.matches(pattern: #"<input\b([^>]*)>"#, options: [.caseInsensitive])
            .reduce(into: [String: String]()) { values, match in
                guard match.count > 1 else { return }
                let attributes = match[1]
                guard attributeValue(named: "type", in: attributes)?.caseInsensitiveCompare(expectedType) == .orderedSame,
                      let name = attributeValue(named: "name", in: attributes)?.nonEmpty else {
                    return
                }
                values[name] = attributeValue(named: "value", in: attributes) ?? ""
            }
    }

    private func firstLinkURL(in html: String, containing marker: String, baseURL: URL) -> URL? {
        html.matches(
            pattern: #"<a\s+([^>]*\bhref\s*=\s*["']([^"']+)["'][^>]*)>"#,
            options: [.caseInsensitive]
        )
        .compactMap { match -> URL? in
            guard match.count > 2 else { return nil }
            let href = match[2].htmlDecoded
            guard href.localizedCaseInsensitiveContains(marker) else { return nil }
            return URL(string: href, relativeTo: baseURL)?.absoluteURL
        }
        .first
    }

    private func inferDate(from cells: [String], rowHTML: String, rowText: String, title: String) -> String {
        if let date = explicitDate(from: rowHTML) {
            return date
        }

        let searchCells = cellsAfterTitle(cells, title: title) + cells
        if let date = searchCells.first(where: { $0.isPostDate }) {
            return date
        }

        return rowText.firstMatch(pattern: #"(\d{2}\.\d{2}\.\d{2}\.?|\d{4}\.\d{2}\.\d{2}\.?|\d{1,2}:\d{2}|방금\s*전|\d+\s*(?:분|시간|일)\s*전)"#) ?? ""
    }

    private func inferNickname(from cells: [String], rowHTML: String, rowText: String, title: String, date: String) -> String {
        if let explicitNickname = explicitNickname(from: rowHTML),
           !explicitNickname.isEmpty,
           explicitNickname != title,
           !explicitNickname.isPostDate {
            return explicitNickname
        }

        if let listInfoNickname = listInfoFields(from: rowHTML)
            .first(where: { $0.isLikelyNickname(excluding: title) }) {
            return listInfoNickname
        }

        if rowHTML.localizedCaseInsensitiveContains("list_cmt")
            && !rowHTML.localizedCaseInsensitiveContains("list_info") {
            return ""
        }

        let afterTitle = cellsAfterTitle(cells, title: title)
        if let dateIndex = afterTitle.firstIndex(where: { $0 == date || $0.isPostDate }) {
            let candidates = afterTitle[..<dateIndex].reversed()
            if let nickname = candidates.first(where: { $0.isLikelyNickname(excluding: title) }) {
                return nickname
            }
        }

        if let titleRange = rowText.range(of: title) {
            let tail = rowText[titleRange.upperBound...]
                .replacingOccurrences(of: date, with: "")
                .replacingOccurrences(of: #"\[\d+\]"#, with: " ", options: .regularExpression)
                .components(separatedBy: " ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if let nickname = tail.first(where: { $0.isLikelyNickname(excluding: title) }) {
                return nickname
            }
        }

        return ""
    }

    private func explicitDate(from rowHTML: String) -> String? {
        let datePatterns = [
            #"<(?:span|time|div)\b[^>]*class=[\"'][^\"']*(?:date|time)[^\"']*[\"'][^>]*>(.*?)</(?:span|time|div)>"#,
            #"<div\b[^>]*class=[\"'][^\"']*list_info[^\"']*[\"'][^>]*>(.*?)</div>"#
        ]

        for pattern in datePatterns {
            let fields = rowHTML.matches(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
                .compactMap { $0.count > 1 ? $0[1].plainHTMLText.nonEmpty : nil }
            if let date = fields.first(where: { $0.isPostDate }) {
                return date
            }
            if let date = fields.compactMap({ $0.firstMatch(pattern: #"(\d{2}\.\d{2}\.\d{2}\.?|\d{4}\.\d{2}\.\d{2}\.?|\d{1,2}:\d{2}|방금\s*전|\d+\s*(?:분|시간|일)\s*전)"#) }).first {
                return date
            }
        }

        return listInfoFields(from: rowHTML).first(where: { $0.isPostDate })
    }

    private func listInfoFields(from rowHTML: String) -> [String] {
        guard let listInfoRange = rowHTML.range(of: #"class=["'][^"']*list_info[^"']*["']"#, options: [.regularExpression, .caseInsensitive]) else {
            return []
        }

        let listInfoHTML = String(rowHTML[listInfoRange.lowerBound...])
            .components(separatedBy: #"class="list_cmt""#).first?
            .components(separatedBy: #"class='list_cmt'"#).first ?? String(rowHTML[listInfoRange.lowerBound...])
        let structuredFields = listInfoHTML.matches(
            pattern: #"<(?:div|span|time)\b[^>]*>(.*?)</(?:div|span|time)>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        .compactMap { $0.count > 1 ? $0[1].plainHTMLText.nonEmpty : nil }
        .filter { field in
            field.isPostDate
                || field.isLikelyNickname(excluding: "")
                || field.firstMatch(pattern: #"^\d+\s*(?:분|시간|일)\s*전$"#) != nil
        }

        if !structuredFields.isEmpty {
            return structuredFields
        }

        return listInfoHTML.plainHTMLText
            .replacingOccurrences(of: #"\s{2,}"#, with: "\n", options: .regularExpression)
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func explicitNickname(from rowHTML: String) -> String? {
        let patterns = [
            #"<(?:span|a)\s*class=[\"'][^\"']*(?:member|author|nick)[^\"']*[\"'][^>]*>(.*?)</(?:span|a)>"#,
            #"<(?:span|a)\b[^>]*class=[\"'][^\"']*(?:member|author|nick)[^\"']*[\"'][^>]*>(.*?)</(?:span|a)>"#,
            #"<div\b[^>]*class=[\"'][^\"']*(?:author|nick)[^\"']*[\"'][^>]*>(.*?)</div>"#
        ]

        for pattern in patterns {
            if let nickname = rowHTML.firstMatch(
                pattern: pattern,
                group: 1,
                options: [.caseInsensitive, .dotMatchesLineSeparators]
            )?.plainHTMLText, !nickname.isEmpty {
                return nickname
            }
        }

        return nil
    }

    private func inferCategory(from cells: [String], title: String) -> String? {
        guard let titleIndex = cells.firstIndex(where: { $0.contains(title) }), titleIndex > 0 else {
            return nil
        }

        let candidate = cells[titleIndex - 1]
        return candidate.isLikelyCategory ? candidate : nil
    }

    private func categoryColorHex(from rowHTML: String, category: String?, categoryID: String?) -> String? {
        if let categoryID,
           let color = rowHTML.firstMatch(
            pattern: #"/category/\#(categoryID)[^\"']*[\"'][^>]*>.*?color\s*:\s*(#[0-9A-Fa-f]{6})"#,
            group: 1,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
           ) {
            return color
        }

        if let category,
           let color = rowHTML.firstMatch(
            pattern: #"<(?:a|span)\b[^>]*>.*?color\s*:\s*(#[0-9A-Fa-f]{6}).*?\#(NSRegularExpression.escapedPattern(for: category))"#,
            group: 1,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
           ) {
            return color
        }

        return categoryColorHex(forCategoryID: categoryID) ?? categoryColorHex(forCategoryTitle: category)
    }

    private func categoryColorHex(forCategoryID categoryID: String?) -> String? {
        guard let categoryID else { return nil }
        return [
            "23941713": "#9bd0ff",
            "36923546": "#e69138",
            "23941775": "#ff0099",
            "28110654": "#68e033",
            "28110676": "#f6b26b",
            "28110645": "#9fc5e8",
            "38624667": "#35a5bd",
            "38624668": "#990000",
            "32500992": "#ff99cc",
            "37269169": "#126aba"
        ][categoryID]
    }

    private func categoryColorHex(forCategoryTitle category: String?) -> String? {
        guard let category else { return nil }
        return [
            "미니": "#9bd0ff",
            "음향": "#e69138",
            "공지": "#ff0099",
            "차량": "#68e033",
            "TV": "#f6b26b",
            "생활": "#9fc5e8",
            "AI": "#35a5bd",
            "로봇": "#990000",
            "리뷰": "#ff99cc",
            "강의": "#126aba"
        ][category]
    }

    private func categoryTitle(forCategoryID categoryID: String?) -> String? {
        guard let categoryID else { return nil }
        return [
            "23941713": "미니",
            "36923546": "음향",
            "23941775": "공지",
            "28110654": "차량",
            "28110676": "TV",
            "28110645": "생활",
            "38624667": "AI",
            "38624668": "로봇",
            "32500992": "리뷰",
            "37269169": "강의"
        ][categoryID]
    }

    private func titleFromCells(_ cells: [String], excluding documentID: String) -> String? {
        cells.first { cell in
            shouldUseTitle(cell)
                && cell != documentID
                && !cell.isPostDate
                && cell.firstMatch(pattern: #"^\d+$"#) == nil
        }
    }

    private func inferCommentCount(from rowHTML: String, title: String) -> Int? {
        let text = rowHTML.plainHTMLText
        if text.contains(title),
           let match = text.firstMatch(pattern: #"\[(\d+)\]"#) {
            return Int(match)
        }

        if let match = rowHTML.firstMatch(
            pattern: #"<a\b[^>]*class=[\"'][^\"']*list_cmt[^\"']*[\"'][^>]*>(\d+)</a>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) {
            return Int(match)
        }

        return nil
    }

    private func inferPostUpvoteCount(from rowHTML: String, cells: [String], title: String, date: String, nickname: String) -> Int {
        if let vote = rowHTML.firstMatch(
            pattern: #"<(?:div|span)\b[^>]*class=[\"'][^\"']*list_vote[^\"']*[\"'][^>]*>.*?(\d+).*?</(?:div|span)>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) {
            return Int(vote) ?? 0
        }

        if rowHTML.localizedCaseInsensitiveContains("<td"),
           let vote = cells.last(where: { $0.firstMatch(pattern: #"^(\d+)$"#) != nil }) {
            return Int(vote) ?? 0
        }

        let trailingNumericCells = cellsAfterTitle(cells, title: title)
            .filter { cell in
                cell != nickname
                    && cell != date
                    && !cell.isPostDate
                    && cell.firstMatch(pattern: #"^(\d+)$"#) != nil
            }

        return trailingNumericCells.last.flatMap(Int.init) ?? 0
    }

    private func cellsAfterTitle(_ cells: [String], title: String) -> [String] {
        guard let index = cells.firstIndex(where: { $0.contains(title) }) else {
            return cells
        }

        return Array(cells.dropFirst(index + 1))
    }

    private func firstMetaContent(named name: String, in html: String) -> String? {
        html.firstMatch(pattern: #"<meta\s+property=[\"']\#(name)[\"']\s+content=[\"']([^\"']+)[\"']"#, group: 1, options: [.caseInsensitive])
    }

    private func bestTitle(from html: String, fallbackTitle: String) -> String {
        let candidates = [
            firstMetaContent(named: "og:title", in: html),
            html.firstMatch(
                pattern: #"<h1\b[^>]*>(.*?)</h1>"#,
                group: 1,
                options: [.caseInsensitive, .dotMatchesLineSeparators]
            ),
            html.firstMatch(
                pattern: #"<(?:h1|h2|div|span)\b[^>]*class=[\"'][^\"']*(?:title|subject)[^\"']*[\"'][^>]*>(.*?)</(?:h1|h2|div|span)>"#,
                group: 1,
                options: [.caseInsensitive, .dotMatchesLineSeparators]
            ),
            fallbackTitle
        ]

        return candidates
            .compactMap { $0?.normalizedPostTitle }
            .filter { shouldUseTitle($0) }
            .max { $0.count < $1.count } ?? fallbackTitle.plainHTMLText
    }

    private func bodyWithoutLeadingTitle(_ body: String, title: String) -> String {
        let lines = body
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let firstLine = lines.first else {
            return body
        }

        let normalizedTitle = title.normalizedPostTitle
        let normalizedFirstLine = firstLine.normalizedPostTitle
        guard normalizedFirstLine == normalizedTitle || normalizedFirstLine.hasPrefix(normalizedTitle) else {
            return body
        }

        return lines.dropFirst().joined(separator: "\n").nonEmpty ?? body
    }

    private func postBodyBlocks(from html: String, title: String, baseURL: URL) -> [MeecoPostBodyBlock] {
        guard !html.isEmpty else { return [] }

        let pattern = #"<iframe\b([^>]*)>|<a\s+([^>]*\bhref\s*=\s*["']([^"']+)["'][^>]*)>(.*?)</a>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }

        let nsHTML = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))
        var blocks: [MeecoPostBodyBlock] = []
        var lastLocation = 0
        var didTrimLeadingTitle = false

        func appendText(from range: NSRange) {
            guard range.location != NSNotFound, range.length > 0 else { return }
            var text = nsHTML.substring(with: range).displayText
            if !didTrimLeadingTitle {
                text = bodyWithoutLeadingTitle(text, title: title)
                didTrimLeadingTitle = true
            }
            guard !text.isEmpty else { return }
            blocks.append(MeecoPostBodyBlock(id: blocks.count, content: .text(text)))
        }

        func appendLinkPreview(url: URL, altText: String) -> Bool {
            guard url.isPreviewableLink else { return false }
            let media = MeecoMedia(
                id: url,
                url: url,
                altText: altText.nonEmpty ?? url.previewTitle,
                kind: .linkPreview
            )
            blocks.append(MeecoPostBodyBlock(id: blocks.count, content: .linkPreview(media)))
            return true
        }

        for match in matches {
            appendText(from: NSRange(location: lastLocation, length: match.range.location - lastLocation))

            var didAppendPreview = false
            if match.range(at: 1).location != NSNotFound {
                let attributes = nsHTML.substring(with: match.range(at: 1))
                if let src = attributeValue(named: "src", in: attributes)?.nonEmpty,
                   let url = URL(string: src, relativeTo: baseURL)?.absoluteURL {
                    didAppendPreview = appendLinkPreview(url: url, altText: url.previewTitle)
                }
            } else if match.range(at: 3).location != NSNotFound {
                let href = nsHTML.substring(with: match.range(at: 3)).htmlDecoded
                let label = match.range(at: 4).location == NSNotFound ? "" : nsHTML.substring(with: match.range(at: 4)).plainHTMLText
                if let url = URL(string: href, relativeTo: baseURL)?.absoluteURL {
                    didAppendPreview = appendLinkPreview(url: url, altText: label)
                }
            }

            if !didAppendPreview {
                appendText(from: match.range)
            }

            lastLocation = match.range.location + match.range.length
        }

        appendText(from: NSRange(location: lastLocation, length: nsHTML.length - lastLocation))
        return blocks
    }

    private func firstContentBlock(in html: String) -> String? {
        let patterns = [
            #"<!--BeforeDocument\([^)]*\)-->(.*?)<!--AfterDocument"#,
            #"<div\b[^>]*class=[\"'][^\"']*xe_content[^\"']*[\"'][^>]*>(.*?)</div>"#,
            #"<article\b[^>]*>(.*?)</article>"#,
            #"<div\b[^>]*class=[\"'][^\"']*rd_body[^\"']*[\"'][^>]*>(.*?)</div>"#,
            #"<div\b[^>]*id=[\"']document_\d+[\"'][^>]*>(.*?)</div>"#
        ]

        for pattern in patterns {
            if let block = html.firstMatch(pattern: pattern, group: 1, options: [.caseInsensitive, .dotMatchesLineSeparators]), !block.displayText.isEmpty {
                return block
            }
        }

        return nil
    }

    private func comments(from html: String, baseURL: URL, postAuthorNickname: String) -> [MeecoComment] {
        let commentHTML = commentSection(in: html) ?? html
        let articleBlocks = commentHTML.matches(
            pattern: #"<article\b([^>]*class=[\"'][^\"']*(?:cmt-el|cmt_unit)[^\"']*[\"'][^>]*)>(.*?)</article>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )

        let legacyBlocks = commentHTML.matches(
            pattern: #"<li\b([^>]*class=[\"'][^\"']*(?:comment|fdb)[^\"']*[\"'][^>]*)>(.*?)</li>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        let blocks = articleBlocks.isEmpty ? legacyBlocks : articleBlocks

        let parsedComments = blocks.compactMap { match -> ParsedComment? in
            guard match.count > 2 else { return nil }
            let attributes = match[1]
            let block = match[2]
            let bodyHTML = block.firstMatch(
                pattern: #"<!--BeforeComment\([^)]*\)-->(.*?)<!--AfterComment"#,
                group: 1,
                options: [.caseInsensitive, .dotMatchesLineSeparators]
            ) ?? block.firstMatch(
                pattern: #"<div\b[^>]*class=[\"'][^\"']*(?:comment_\d+_\d+|xe_content)[^\"']*[\"'][^>]*>(.*?)</div>"#,
                group: 1,
                options: [.caseInsensitive, .dotMatchesLineSeparators]
            ) ?? block
            let body = bodyHTML.displayText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard body.count > 2 else { return nil }
            let nickname = explicitNickname(from: block) ?? ""
            let date = block.firstMatch(pattern: #"(\d{4}\.\d{2}\.\d{2}\.?\s*\d{2}:\d{2}|\d{2}\.\d{2}\.\d{2}\.?|\d{1,2}:\d{2}|방금\s*전|\d+\s*(?:분|시간|일)\s*전)"#) ?? ""
            let media = mediaItems(from: bodyHTML, baseURL: baseURL)
            let upvoteCount = commentUpvoteCount(from: block)
            let explicitDepth = commentReplyDepth(attributes: attributes, block: block)
            let targetNickname = commentTargetNickname(from: block)
            return ParsedComment(
                nickname: nickname,
                date: date,
                body: body,
                media: media,
                upvoteCount: upvoteCount,
                explicitDepth: explicitDepth,
                targetNickname: targetNickname
            )
        }

        var lastDepthByNickname: [String: Int] = [:]
        let postAuthorKey = normalizedNickname(postAuthorNickname)

        return parsedComments.map { parsedComment in
            let targetDepth = parsedComment.targetNickname
                .map(normalizedNickname)
                .flatMap { lastDepthByNickname[$0] }
            let resolvedDepth: Int
            if let targetDepth {
                resolvedDepth = min(max(targetDepth + 1, parsedComment.explicitDepth), 6)
            } else {
                resolvedDepth = parsedComment.explicitDepth
            }

            let nicknameKey = normalizedNickname(parsedComment.nickname)
            if !nicknameKey.isEmpty {
                lastDepthByNickname[nicknameKey] = resolvedDepth
            }

            return MeecoComment(
                nickname: parsedComment.nickname,
                date: parsedComment.date,
                body: parsedComment.body,
                media: parsedComment.media,
                upvoteCount: parsedComment.upvoteCount,
                replyDepth: resolvedDepth,
                isPostAuthor: !postAuthorKey.isEmpty && nicknameKey == postAuthorKey
            )
        }
    }

    private func commentTargetNickname(from block: String) -> String? {
        guard let targetText = block.firstMatch(
            pattern: #"<div\b[^>]*class=["'][^"']*cmt_to[^"']*["'][^>]*>(.*?)</div>"#,
            group: 1,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )?.plainHTMLText.nonEmpty else {
            return nil
        }

        return targetText
            .replacingOccurrences(of: "@", with: "")
            .replacingOccurrences(of: "님에게", with: "")
            .replacingOccurrences(of: "님", with: "")
            .components(separatedBy: .newlines)
            .joined(separator: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty
    }

    private func normalizedNickname(_ nickname: String) -> String {
        nickname
            .plainHTMLText
            .replacingOccurrences(of: "@", with: "")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func commentReplyDepth(attributes: String, block: String) -> Int {
        let loweredAttributes = attributes.lowercased()
        let loweredBlock = block.lowercased()

        if let depthText = loweredAttributes.firstMatch(pattern: #"(?:depth|indent|reply)[_-]?(\d+)"#),
           let depth = Int(depthText) {
            return max(1, min(depth, 6))
        }

        if loweredAttributes.firstMatch(pattern: #"class\s*=\s*["'][^"']*(?:^|\s)(?:reply|recomment)(?:\s|$)[^"']*["']"#) != nil
            || loweredBlock.firstMatch(pattern: #"<i\b[^>]*class=["'][^"']*icon_reply[^"']*["']"#) != nil
            || loweredBlock.firstMatch(pattern: #"<div\b[^>]*class=["'][^"']*cmt_to[^"']*["']"#) != nil {
            return 1
        }

        return 0
    }

    private func commentSection(in html: String) -> String? {
        guard let commentStart = html.range(
            of: #"<div\b[^>]*id=["']comment["'][^>]*>"#,
            options: [.regularExpression, .caseInsensitive]
        )?.lowerBound else {
            return nil
        }

        let tail = String(html[commentStart...])
        let endMarkers = [
            #"<div\b[^>]*class=["'][^"']*list_d[^"']*["']"#,
            #"<div\b[^>]*class=["'][^"']*bd_lst[^"']*["']"#,
            #"<footer\b"#
        ]

        for marker in endMarkers {
            if let end = tail.range(of: marker, options: [.regularExpression, .caseInsensitive])?.lowerBound,
               end > tail.startIndex {
                return String(tail[..<end])
            }
        }

        return tail
    }

    private func commentUpvoteCount(from block: String) -> Int {
        block.firstMatch(
            pattern: #"<span\b[^>]*class=[\"'][^\"']*cmt_vote_up[^\"']*[\"'][^>]*>.*?<b\b[^>]*class=[\"'][^\"']*num[^\"']*[\"'][^>]*>(\d+)</b>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ).flatMap(Int.init) ?? 0
    }

    private func mediaItems(from html: String, baseURL: URL) -> [MeecoMedia] {
        var seen = Set<URL>()
        var items: [MeecoMedia] = []

        func appendMedia(url: URL, altText: String, kind: MeecoMedia.Kind) {
            guard seen.insert(url).inserted else { return }
            items.append(MeecoMedia(id: url, url: url, altText: altText, kind: kind))
        }

        let imageMatches = html.matches(
            pattern: #"<img\b([^>]*)>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        for match in imageMatches {
            guard match.count > 1 else { continue }
            let attributes = match[1]
            guard let src = mediaSource(in: attributes),
                  let url = URL(string: src, relativeTo: baseURL)?.absoluteURL,
                  shouldUseImageURL(url) else {
                continue
            }

            appendMedia(url: url, altText: attributeValue(named: "alt", in: attributes)?.plainHTMLText ?? "", kind: .image)
        }

        let videoMatches = html.matches(
            pattern: #"<(?:video|source)\b([^>]*)>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        for match in videoMatches {
            guard match.count > 1,
                  let src = mediaSource(in: match[1]),
                  let url = URL(string: src, relativeTo: baseURL)?.absoluteURL,
                  shouldUseVideoURL(url) else {
                continue
            }

            appendMedia(url: url, altText: "첨부 동영상", kind: .video)
        }

        let iframeMatches = html.matches(
            pattern: #"<iframe\b([^>]*)>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        for match in iframeMatches {
            guard match.count > 1,
                  let src = attributeValue(named: "src", in: match[1])?.nonEmpty,
                  let url = URL(string: src, relativeTo: baseURL)?.absoluteURL,
                  url.isPreviewableLink else {
                continue
            }

            appendMedia(url: url, altText: url.previewTitle, kind: .linkPreview)
        }

        let linkMatches = html.matches(
            pattern: #"<a\s+([^>]*\bhref\s*=\s*[\"']([^\"']+)[\"'][^>]*)>(.*?)</a>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        for match in linkMatches {
            guard match.count > 3,
                  let url = URL(string: match[2].htmlDecoded, relativeTo: baseURL)?.absoluteURL else {
                continue
            }

            let label = match[3].plainHTMLText
            if shouldUseImageURL(url) {
                appendMedia(url: url, altText: label, kind: .image)
            } else if shouldUseVideoURL(url) {
                appendMedia(url: url, altText: label.nonEmpty ?? "첨부 동영상", kind: .video)
            } else if url.isPreviewableLink {
                appendMedia(url: url, altText: label.nonEmpty ?? url.previewTitle, kind: .linkPreview)
            }
        }

        return items
    }

    private func thumbnailURL(from html: String, baseURL: URL) -> URL? {
        let backgroundMatches = html.matches(
            pattern: #"background-image\s*:\s*url\((['\"]?)(.*?)\1\)"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        for match in backgroundMatches {
            guard match.count > 2,
                  let url = URL(string: match[2].htmlDecoded, relativeTo: baseURL)?.absoluteURL,
                  shouldUseImageURL(url) else {
                continue
            }
            return url
        }

        return mediaItems(from: html, baseURL: baseURL).first { $0.kind == .image }?.url
    }

    private func mediaSource(in attributes: String) -> String? {
        let candidates = [
            attributeValue(named: "src", in: attributes),
            attributeValue(named: "data-src", in: attributes),
            attributeValue(named: "data-original", in: attributes),
            attributeValue(named: "data-lazy-src", in: attributes),
            attributeValue(named: "poster", in: attributes),
            attributeValue(named: "srcset", in: attributes)?.components(separatedBy: ",").first?.components(separatedBy: .whitespaces).first
        ]

        return candidates.compactMap { $0?.htmlDecoded.nonEmpty }.first
    }

    private func shouldUseImageURL(_ url: URL) -> Bool {
        let path = url.path.lowercased()
        guard path.hasSuffix(".jpg")
            || path.hasSuffix(".jpeg")
            || path.hasSuffix(".png")
            || path.hasSuffix(".gif")
            || path.hasSuffix(".webp")
            || path.hasSuffix(".heic")
            || path.hasSuffix(".heif") else {
            return false
        }

        return !path.contains("/profile_image/")
            && !path.contains("/addons/")
            && !path.contains("/images/new")
            && !path.contains("/modules/")
            && !path.contains("/layouts/")
    }

    private func shouldUseVideoURL(_ url: URL) -> Bool {
        let path = url.path.lowercased()
        return path.hasSuffix(".mp4")
            || path.hasSuffix(".mov")
            || path.hasSuffix(".m4v")
            || path.hasSuffix(".webm")
    }

    private func unique(_ posts: [MeecoPost]) -> [MeecoPost] {
        var indexByURL: [URL: Int] = [:]
        var result: [MeecoPost] = []

        for post in posts {
            if let existingIndex = indexByURL[post.url] {
                result[existingIndex] = mergedPost(result[existingIndex], with: post)
            } else {
                indexByURL[post.url] = result.count
                result.append(post)
                if result.count == 80 {
                    break
                }
            }
        }

        return result
    }

    private func mergedPost(_ current: MeecoPost, with candidate: MeecoPost) -> MeecoPost {
        MeecoPost(
            id: current.id,
            documentID: current.documentID,
            title: current.title.isEmpty ? candidate.title : current.title,
            nickname: current.nickname.nonEmpty ?? candidate.nickname,
            date: current.date.nonEmpty ?? candidate.date,
            url: current.url,
            boardPath: current.boardPath,
            category: current.category ?? candidate.category,
            commentCount: current.commentCount ?? candidate.commentCount,
            upvoteCount: max(current.upvoteCount, candidate.upvoteCount),
            isNotice: current.isNotice || candidate.isNotice,
            isHot: current.isHot || candidate.isHot,
            categoryColorHex: current.categoryColorHex ?? candidate.categoryColorHex,
            thumbnailURL: current.thumbnailURL ?? candidate.thumbnailURL
        )
    }

    private func shouldUseTitle(_ title: String) -> Bool {
        guard title.count >= 2 else { return false }
        guard !ignoredTitles.contains(title) else { return false }
        guard title.firstMatch(pattern: #"^\d+$"#) == nil else { return false }
        guard !title.localizedCaseInsensitiveContains("Image:") else { return false }
        guard !title.hasPrefix("[") || !title.hasSuffix("]") else { return false }
        return true
    }
}

private struct ArticleAnchor {
    let url: URL
    let title: String
    let boardPath: String
    let documentID: String
    let categoryID: String?
    let isTitleLink: Bool
}

private struct ParsedComment {
    let nickname: String
    let date: String
    let body: String
    let media: [MeecoMedia]
    let upvoteCount: Int
    let explicitDepth: Int
    let targetNickname: String?
}

private extension String {
    var boardIDSet: Set<String> {
        Set(split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    var plainHTMLText: String {
        replacingOccurrences(of: #"<script\b[^>]*>.*?</script>"#, with: " ", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"<style\b[^>]*>.*?</style>"#, with: " ", options: [.regularExpression, .caseInsensitive])
            .removingHTMLTags
            .htmlDecoded
            .removingHTMLTags
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayText: String {
        replacingOccurrences(of: #"<script\b[^>]*>.*?</script>"#, with: " ", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"<style\b[^>]*>.*?</style>"#, with: " ", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"<br\b[^>]*>"#, with: "\n", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"</?(p|div|li|tr|h[1-6]|blockquote)\b[^>]*>"#, with: "\n", options: [.regularExpression, .caseInsensitive])
            .removingHTMLTags
            .htmlDecoded
            .removingHTMLTags
            .replacingOccurrences(of: #"[ \t]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\n[ \t]+"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var removingHTMLTags: String {
        replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
    }

    var htmlDecoded: String {
        var decoded = self
        let entities = [
            "&amp;": "&",
            "&quot;": "\"",
            "&#34;": "\"",
            "&#39;": "'",
            "&apos;": "'",
            "&lt;": "<",
            "&gt;": ">",
            "&nbsp;": " "
        ]

        for (entity, character) in entities {
            decoded = decoded.replacingOccurrences(of: entity, with: character)
        }

        return decoded.decodingNumericHTMLEntities
    }

    var decodingNumericHTMLEntities: String {
        var decoded = self
        let matches = decoded.matches(pattern: #"&#(x?[0-9A-Fa-f]+);"#)
        for match in matches.reversed() {
            guard match.count > 1 else { continue }
            let token = match[1]
            let radix = token.lowercased().hasPrefix("x") ? 16 : 10
            let digits = radix == 16 ? String(token.dropFirst()) : token
            guard let scalarValue = UInt32(digits, radix: radix),
                  let scalar = UnicodeScalar(scalarValue) else {
                continue
            }
            decoded = decoded.replacingOccurrences(of: match[0], with: String(Character(scalar)))
        }
        return decoded
    }

    var nonEmpty: String? {
        isEmpty ? nil : self
    }

    var normalizedDealStatus: String? {
        let normalized = plainHTMLText
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        if normalized.contains("종료") || normalized.localizedCaseInsensitiveContains("expired") || normalized.localizedCaseInsensitiveContains("sold out") {
            return "종료"
        }
        if normalized.contains("진행") || normalized.contains("판매") || normalized.localizedCaseInsensitiveContains("active") || normalized.localizedCaseInsensitiveContains("available") {
            return "진행 중"
        }
        return normalized
    }

    var normalizedPostTitle: String {
        plainHTMLText
            .replacingOccurrences(of: #"(?i)\s*-\s*미코\s*$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isPostDate: Bool {
        firstMatch(pattern: #"^(\d{2}\.\d{2}\.\d{2}\.?|\d{4}\.\d{2}\.\d{2}\.?|\d{1,2}:\d{2}|방금\s*전|\d+\s*(?:분|시간|일)\s*전)$"#) != nil
    }

    var isLikelyCategory: Bool {
        !isEmpty && count <= 8 && firstMatch(pattern: #"\d"#) == nil
    }

    func isLikelyNickname(excluding title: String) -> Bool {
        if self == "익명" || localizedCaseInsensitiveCompare("Anonymous") == .orderedSame {
            return true
        }
        guard !isEmpty, self != title, !contains(title), count <= 24 else { return false }
        guard firstMatch(pattern: #"^\d+$"#) == nil else { return false }
        guard firstMatch(pattern: #"^\[\d+\]$"#) == nil else { return false }
        guard !isPostDate else { return false }
        let excluded = ["공지", "핫글", "미니", "음향", "소식", "리뷰", "차량", "TV", "생활", "file", "update"]
        return !excluded.contains(self)
    }

    func matches(pattern: String, options: NSRegularExpression.Options = []) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return []
        }

        let nsRange = NSRange(startIndex..<endIndex, in: self)
        return regex.matches(in: self, range: nsRange).map { result in
            (0..<result.numberOfRanges).map { index in
                guard let range = Range(result.range(at: index), in: self) else { return "" }
                return String(self[range])
            }
        }
    }

    func firstMatch(pattern: String, group: Int = 1, options: NSRegularExpression.Options = []) -> String? {
        matches(pattern: pattern, options: options).first.flatMap { match in
            guard match.indices.contains(group) else { return nil }
            return match[group]
        }
    }
}

private extension Set where Element == String {
    var boardIDStorageValue: String {
        sorted().joined(separator: ",")
    }
}

private extension MeecoPost {
    var categoryBadgeColor: Color {
        categoryColorHex.flatMap(Color.init(hex:)) ?? (isNotice ? .meecoCrimson : .accentColor)
    }

    var sourceBoardTitle: String? {
        switch boardPath {
        case "news": return "IT소식"
        case "mini": return "미니"
        case "Review": return "리뷰"
        case "big": return "대형"
        case "AI": return "AI"
        case "free": return "자유"
        case "humor": return "유머"
        case "Gallery": return "갤러리"
        case "anonymous": return "익명"
        case "Price": return "특가"
        case "Purchase": return "구매"
        case "market": return "장터"
        case "Enterprise": return "홍보"
        case "Event": return "이벤트"
        case "BugUpdate": return "개선"
        case "notice": return "공지"
        case "Makgora": return "막고라"
        case "Balloon": return "도네"
        default: return nil
        }
    }

    var sourceBoardBadgeColor: Color {
        switch boardPath {
        case "news": return .blue
        case "mini": return .cyan
        case "Review": return .pink
        case "big": return .orange
        case "AI": return .teal
        case "free": return .green
        case "humor": return .yellow
        case "Gallery": return .purple
        case "anonymous": return .gray
        case "Price": return .red
        case "Purchase": return .mint
        case "market": return .brown
        case "Enterprise": return .indigo
        case "Event": return .pink
        case "BugUpdate": return .blue
        case "notice": return .meecoCrimson
        case "Makgora": return .orange
        case "Balloon": return .purple
        default: return .accentColor
        }
    }
}

private extension Array where Element == MeecoNotification {
    var sortedForDisplay: [MeecoNotification] {
        sorted { lhs, rhs in
            if lhs.isUnread != rhs.isUnread {
                return lhs.isUnread && !rhs.isUnread
            }
            return lhs.date > rhs.date
        }
    }
}

private extension Color {
    static let meecoCrimson = Color(red: 1.0, green: 0.0, blue: 0.6)

    init?(hex: String) {
        var normalized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasPrefix("#") {
            normalized.removeFirst()
        }

        guard normalized.count == 6,
              let value = Int(normalized, radix: 16) else {
            return nil
        }

        self.init(
            red: Double((value >> 16) & 0xff) / 255.0,
            green: Double((value >> 8) & 0xff) / 255.0,
            blue: Double(value & 0xff) / 255.0
        )
    }
}

private extension URL {
    var normalizedHost: String {
        (host ?? "").lowercased().replacingOccurrences(of: "www.", with: "")
    }

    var isPreviewableLink: Bool {
        guard scheme?.lowercased().hasPrefix("http") == true else { return false }
        let host = normalizedHost
        return host == "youtube.com"
            || host == "youtu.be"
            || host == "m.youtube.com"
            || host == "x.com"
            || host == "twitter.com"
            || host == "instagram.com"
            || host == "threads.net"
            || host == "facebook.com"
            || host == "m.facebook.com"
            || host == "fb.watch"
    }

    var previewTitle: String {
        switch normalizedHost {
        case "youtube.com", "m.youtube.com", "youtu.be":
            return "YouTube"
        case "x.com", "twitter.com":
            return "X"
        case "instagram.com":
            return "Instagram"
        case "threads.net":
            return "Threads"
        case "facebook.com", "m.facebook.com", "fb.watch":
            return "Facebook"
        default:
            return host ?? absoluteString
        }
    }

    var previewSystemImage: String {
        switch normalizedHost {
        case "youtube.com", "m.youtube.com", "youtu.be":
            return "play.rectangle.fill"
        case "instagram.com":
            return "camera.fill"
        case "x.com", "twitter.com", "threads.net":
            return "quote.bubble.fill"
        case "facebook.com", "m.facebook.com", "fb.watch":
            return "f.circle.fill"
        default:
            return "link"
        }
    }

    var youtubeThumbnailURL: URL? {
        guard let videoID = youtubeVideoID else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg")
    }

    private var youtubeVideoID: String? {
        let host = normalizedHost
        if host == "youtu.be" {
            return pathComponents.filter { $0 != "/" }.first
        }

        if host == "youtube.com" || host == "m.youtube.com" {
            let components = URLComponents(url: self, resolvingAgainstBaseURL: false)
            if let id = components?.queryItems?.first(where: { $0.name == "v" })?.value {
                return id
            }

            let pathParts = pathComponents.filter { $0 != "/" }
            if let shortsIndex = pathParts.firstIndex(of: "shorts"), pathParts.indices.contains(shortsIndex + 1) {
                return pathParts[shortsIndex + 1]
            }
            if let embedIndex = pathParts.firstIndex(of: "embed"), pathParts.indices.contains(embedIndex + 1) {
                return pathParts[embedIndex + 1]
            }
        }

        return nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
