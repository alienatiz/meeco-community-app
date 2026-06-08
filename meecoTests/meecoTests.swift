//
//  meecoTests.swift
//  meecoTests
//

import XCTest
@testable import meeco

final class meecoTests: XCTestCase {
    func testExample() throws {
        XCTAssertTrue(true)
    }

    func testPerformanceExample() throws {
        measure { }
    }

    func testParserExtractsBoardRowsInDocumentNickDateOrder() throws {
        let html = """
        <table>
            <tr>
                <td>245404</td>
                <td><a href=\"/mini/category/1\">미니</a></td>
                <td><a href=\"https://meeco.kr/mini/41481365\">8.5 상단바 좀 이상하군요</a> <a href=\"/mini/41481365#comment\">[6]</a></td>
                <td>kty4</td>
                <td>02:09</td>
                <td>210</td>
                <td>2</td>
            </tr>
            <tr>
                <td>245403</td>
                <td><a href=\"/mini/category/1\">미니</a></td>
                <td><a href=\"/mini/41481364\">갤럭시 점프3 펌웨어 업데이트</a></td>
                <td>운김</td>
                <td>26.06.04</td>
                <td>377</td>
                <td>2</td>
            </tr>
        </table>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.count, 2)
        XCTAssertEqual(posts[0].title, "8.5 상단바 좀 이상하군요")
        XCTAssertEqual(posts[0].nickname, "kty4")
        XCTAssertEqual(posts[0].date, "02:09")
        XCTAssertEqual(posts[0].commentCount, 6)
        XCTAssertEqual(posts[0].documentID, "41481365")
        XCTAssertEqual(posts[1].title, "갤럭시 점프3 펌웨어 업데이트")
        XCTAssertEqual(posts[1].nickname, "운김")
        XCTAssertEqual(posts[1].date, "26.06.04")
    }

    func testParserHonorsSelectedBoard() throws {
        let html = """
        <tr><td><a href=\"/mini/41481365\">미니 게시물</a></td><td>민이</td><td>02:09</td></tr>
        <tr><td><a href=\"/news/41474262\">뉴스 게시물</a></td><td>뉴스봇</td><td>26.06.04</td></tr>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/news")!,
            allowedBoardPaths: ["news"]
        )

        XCTAssertEqual(posts.map(\.title), ["뉴스 게시물"])
        XCTAssertEqual(posts.map(\.nickname), ["뉴스봇"])
    }

    func testParserPrefersDocumentTitleOverReplyLinkAndDocumentID() throws {
        let html = """
        <tr>
            <td>245404</td>
            <td>미니</td>
            <td>
                <a href=\"/mini/41481365#bCmt\" class=\"ptCl num\" title=\"Replies\">[6]</a>
                <a class=\"title_a\" href=\"/mini/41481365\">8.5 상단바 좀 이상하군요</a>
            </td>
            <td class=\"author\">kty4</td>
            <td class=\"num\">26.06.05</td>
        </tr>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.first?.title, "8.5 상단바 좀 이상하군요")
        XCTAssertNotEqual(posts.first?.title, "41481365")
        XCTAssertNotEqual(posts.first?.title, "245404")
        XCTAssertNotEqual(posts.first?.title, "[6]")
    }

    func testParserShowsRealTitleForDocument41482340() throws {
        let html = """
        <tr>
            <td class=\"num\">245414</td>
            <td class=\"category\">
                <a href=\"/mini/category/23941713\">미니</a>
            </td>
            <td class=\"title\">
                <a class=\"title_a\" href=\"/mini/41482340\">
                    <span>삼성클라우드 폴드 언팩때 나오려나요</span>
                </a>
                <a href=\"/mini/41482340#bCmt\" class=\"ptCl num\" title=\"Replies\">[10]</a>
            </td>
            <td class=\"author\"><a href=\"#popup_menu_area\">존버합니다</a></td>
            <td class=\"num\">26.06.05</td>
            <td class=\"num\"><span>632</span></td>
            <td class=\"num\"><span>5</span></td>
        </tr>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.first?.documentID, "41482340")
        XCTAssertEqual(posts.first?.title, "삼성클라우드 폴드 언팩때 나오려나요")
        XCTAssertNotEqual(posts.first?.title, "41482340")
        XCTAssertNotEqual(posts.first?.title, "245414")
    }

    func testParserShowsTextTitleForEveryDocumentRow() throws {
        let html = """
        <tr>
            <td class=\"num\">245414</td>
            <td class=\"category\"><a href=\"/mini/category/23941713\">미니</a></td>
            <td class=\"title\">
                <a class=\"title_a\" href=\"/mini/41482340\"><span>삼성클라우드 폴드 언팩때 나오려나요</span></a>
                <a href=\"/mini/41482340#bCmt\" class=\"ptCl num\">[10]</a>
            </td>
            <td class=\"author\">존버합니다</td>
            <td class=\"num\">26.06.05</td>
        </tr>
        <tr>
            <td class=\"num\">245413</td>
            <td class=\"category\"><a href=\"/mini/category/23941713\">미니</a></td>
            <td class=\"title\">
                <a class=\"title_a\" href=\"/mini/41482275\"><span>아이폰 알림센터가 꽤 마음에 드네요</span></a>
                <a href=\"/mini/41482275#bCmt\" class=\"ptCl num\">[15]</a>
            </td>
            <td class=\"author\">조까를로스</td>
            <td class=\"num\">26.06.05</td>
        </tr>
        <tr>
            <td class=\"num\">245412</td>
            <td class=\"category\"><a href=\"/mini/category/36923546\">음향</a></td>
            <td class=\"title\">
                <a class=\"title_a\" href=\"/mini/41481812\"><span>무선이어폰 노캔 체감 질문드립니다</span></a>
                <a href=\"/mini/41481812#bCmt\" class=\"ptCl num\">[2]</a>
            </td>
            <td class=\"author\">CountDooku</td>
            <td class=\"num\">26.06.05</td>
        </tr>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.map(\.documentID), ["41482340", "41482275", "41481812"])
        XCTAssertEqual(posts.map(\.title), [
            "삼성클라우드 폴드 언팩때 나오려나요",
            "아이폰 알림센터가 꽤 마음에 드네요",
            "무선이어폰 노캔 체감 질문드립니다"
        ])
        XCTAssertFalse(posts.contains { $0.title == $0.documentID })
        XCTAssertFalse(posts.contains { !$0.title.isEmpty && $0.title.allSatisfy(\.isNumber) })
    }

    func testParserReadsMobileListLinkTitleAttribute() throws {
        let html = """
        <li>
            <a class=\"list_link\" href=\"/mini/41482340\" title=\"삼성클라우드 폴드 언팩때 나오려나요\"></a>
            <a class=\"list_cmt\" href=\"/mini/41482340#comment\">10</a>
        </li>
        <li>
            <a class=\"list_link\" href=\"/mini/41481365\" title=\"8.5 상단바 좀 이상하군요\"></a>
            <a class=\"list_cmt\" href=\"/mini/41481365#comment\">6</a>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.map(\.documentID), ["41482340", "41481365"])
        XCTAssertEqual(posts.map(\.title), [
            "삼성클라우드 폴드 언팩때 나오려나요",
            "8.5 상단바 좀 이상하군요"
        ])
    }

    func testParserReadsMobileMemberNicknameInsteadOfMemberNumber() throws {
        let html = """
        <li class=\"has_cmt\">
            <a class=\"list_link\" href=\"/mini/41483426\" title=\"근데 플립단종이 아니라\"></a>
            <div class=\"list_title\"><span class=\"list_ctg\">미니</span>근데 플립단종이 아니라</div>
            <div class=\"list_info\">
                <div><span class=\"member_34893294\">치즈볼</span></div>
                <div>2시간 전</div>
                <div><i class=\"xi-eye\"></i> 440</div>
                <div class=\"list_vote\"><i class=\"xi-heart\"></i> 1</div>
            </div>
            <a class=\"list_cmt\" href=\"/mini/41483426#comment\">3</a>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.first?.nickname, "치즈볼")
        XCTAssertNotEqual(posts.first?.nickname, "34893294")
        XCTAssertNotEqual(posts.first?.nickname, "440")
    }

    func testParserReadsMobileFullViewSpanMetadata() throws {
        let html = """
        <li class=\"has_cmt\">
            <a class=\"list_link\" href=\"/mini/41490001\" title=\"풀뷰 메타데이터 확인\"></a>
            <div class=\"list_title\"><span class=\"list_ctg\">미니</span>풀뷰 메타데이터 확인</div>
            <div class=\"list_info\">
                <span class=\"member_38635502\">digi</span>
                <span class=\"date\">26.06.07.</span>
                <span><i class=\"xi-eye\"></i> 102</span>
                <span class=\"list_vote\"><i class=\"xi-heart\"></i> 3</span>
            </div>
            <a class=\"list_cmt\" href=\"/mini/41490001#comment\">5</a>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.first?.nickname, "digi")
        XCTAssertEqual(posts.first?.date, "26.06.07.")
        XCTAssertEqual(posts.first?.commentCount, 5)
        XCTAssertEqual(posts.first?.upvoteCount, 3)
    }

    func testParserMergesMiniPromotedRowsWithLaterMetadataDuplicate() throws {
        let html = """
        <li class=\"has_cmt\">
            <a class=\"list_link\" href=\"/mini/41484658\" title=\"폴드 와이드 케이스업체발 유출..?\"></a>
            <span class=\"hot_text\">핫글</span>
            <div class=\"list_title\"><span>폴드 와이드 케이스업체발 유출..?</span></div>
            <a class=\"list_cmt\" href=\"https://meeco.kr/mini/41484658#comment\">5</a>
        </li>
        <li class=\"has_cmt\">
            <a class=\"list_link\" href=\"/mini/41484658\" title=\"폴드 와이드 케이스업체발 유출..?\"></a>
            <div class=\"list_title\"><span class=\"list_ctg\">미니</span>폴드 와이드 케이스업체발 유출..?</div>
            <div class=\"list_info\">
                <div><span class=\"member_33441145\">BENIGN</span></div>
                <div>2시간 전</div>
                <div><i class=\"xi-eye\"></i> 595</div>
                <div class=\"list_vote\"><i class=\"xi-heart\"></i> 7</div>
            </div>
            <a class=\"list_cmt\" href=\"/mini/41484658#comment\">5</a>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.count, 1)
        XCTAssertEqual(posts.first?.title, "폴드 와이드 케이스업체발 유출..?")
        XCTAssertEqual(posts.first?.nickname, "BENIGN")
        XCTAssertEqual(posts.first?.date, "2시간 전")
        XCTAssertEqual(posts.first?.commentCount, 5)
        XCTAssertEqual(posts.first?.upvoteCount, 7)
        XCTAssertEqual(posts.first?.isHot, true)
    }

    func testParserKeepsAnonymousNickname() throws {
        let html = """
        <li>
            <a class=\"list_link\" href=\"/mini/41483427\" title=\"익명 작성 테스트\"></a>
            <div class=\"list_title\"><span class=\"list_ctg\">미니</span>익명 작성 테스트</div>
            <div class=\"list_info\">
                <div><span class=\"member_0\">익명</span></div>
                <div>3시간 전</div>
                <div><i class=\"xi-eye\"></i> 120</div>
            </div>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.first?.nickname, "익명")
    }

    func testParserDoesNotUseMobileCommentCountAsNickname() throws {
        let html = """
        <li class=\"has_cmt\">
            <a class=\"list_link\" href=\"/mini/41483428\" title=\"댓글 숫자 닉네임 방지\"></a>
            <span class=\"hot_text\">핫글</span>
            <div class=\"list_title\">댓글 숫자 닉네임 방지</div>
            <a class=\"list_cmt\" href=\"/mini/41483428#comment\">14</a>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.first?.nickname, "")
        XCTAssertNotEqual(posts.first?.nickname, "14")
    }

    func testParserReadsMobileListInfoNicknameAndDate() throws {
        let html = """
        <li class=\"has_cmt\">
            <a class=\"list_link\" href=\"/mini/41483429\" title=\"리스트 정보 메타데이터\"></a>
            <div class=\"list_title\"><span class=\"list_ctg\">미니</span>리스트 정보 메타데이터</div>
            <div class=\"list_info\">
                <div>실명닉</div>
                <div>2시간 전</div>
                <div><i class=\"xi-eye\"></i> 440</div>
                <div class=\"list_vote\"><i class=\"xi-heart\"></i> 1</div>
            </div>
            <a class=\"list_cmt\" href=\"/mini/41483429#comment\">7</a>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.first?.nickname, "실명닉")
        XCTAssertEqual(posts.first?.date, "2시간 전")
    }

    func testParserReadsExplicitNumericNicknameAndTrailingDotDate() throws {
        let html = """
        <li class=\"has_cmt\">
            <a class=\"list_link\" href=\"/mini/41483156?category=36923546\" title=\"사운드코어 리버티5 프로 후기\"></a>
            <div class=\"list_title\"><span class=\"list_ctg\">음향</span>사운드코어 리버티5 프로 후기</div>
            <div class=\"list_info\"><div><span class=\"member_37924502\">212212</span></div><div>26.06.05.</div><div><i class=\"xi-eye\"></i> 322</div></div>
            <div style=\"color:#ff0066;\" class=\"list_vote\"><i class=\"xi-heart\"></i> 4</div>
            <a class=\"list_cmt\" href=\"/mini/41483156?category=36923546#comment\">7</a>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini/category/36923546")!,
            allowedBoardPaths: ["mini"],
            category: MeecoBoard.mini.categories[1]
        )

        XCTAssertEqual(posts.first?.nickname, "212212")
        XCTAssertEqual(posts.first?.date, "26.06.05.")
        XCTAssertEqual(posts.first?.commentCount, 7)
        XCTAssertEqual(posts.first?.upvoteCount, 4)
    }

    func testParserRemovesHTMLTagsFromPostListTitles() throws {
        let html = """
        <li>
            <a class=\"list_link\" href=\"/mini/41482340\" title=\"&lt;b&gt;삼성클라우드&lt;/b&gt; 폴드\"></a>
        </li>
        <li>
            <a class=\"list_link\" href=\"/mini/41482341\"><span><em>아이폰</em> 알림센터</span></a>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.map(\.title), ["삼성클라우드 폴드", "아이폰 알림센터"])
        XCTAssertFalse(posts.contains { $0.title.contains("<") || $0.title.contains(">") })
    }

    func testParserRemovesNumericEncodedHTMLTagsFromTitles() throws {
        let html = """
        <li>
            <a class=\"list_link\" href=\"/mini/41482340\" title=\"&#60;b&#62;삼성클라우드&#60;/b&#62; 폴드\"></a>
        </li>
        <li>
            <a class=\"list_link\" href=\"/mini/41482341\" title=\"&#x3C;em&#x3E;아이폰&#x3C;/em&#x3E; 알림센터\"></a>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.map(\.title), ["삼성클라우드 폴드", "아이폰 알림센터"])
        XCTAssertFalse(posts.contains { $0.title.contains("<") || $0.title.contains(">") })
    }

    func testBoardPageURLUsesNormalPagination() throws {
        XCTAssertEqual(MeecoBoard.mini.pageURL(1).absoluteString, "https://meeco.kr/mini")
        XCTAssertEqual(MeecoBoard.mini.pageURL(2).absoluteString, "https://meeco.kr/mini?page=2")

        let board = MeecoBoard(
            id: "search",
            title: "검색",
            description: "검색 결과",
            systemImage: "magnifyingglass",
            url: URL(string: "https://meeco.kr/mini?category=23941713")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(board.pageURL(3).absoluteString, "https://meeco.kr/mini?category=23941713&page=3")
    }

    func testBoardCategoriesUseSiteCategoryURLs() throws {
        XCTAssertEqual(MeecoBoard.mini.categories.map(\.title), ["미니", "음향", "공지"])
        XCTAssertEqual(MeecoBoard.review.categories.map(\.title), ["리뷰", "강의"])
        XCTAssertEqual(MeecoBoard.big.categories.map(\.title), ["차량", "TV", "생활"])
        XCTAssertEqual(MeecoBoard.ai.categories.map(\.title), ["AI", "로봇"])

        XCTAssertEqual(
            MeecoBoard.mini.pageURL(2, category: MeecoBoard.mini.categories[1]).absoluteString,
            "https://meeco.kr/mini/category/36923546?page=2"
        )
        XCTAssertEqual(
            MeecoBoard.ai.pageURL(1, category: MeecoBoard.ai.categories[1]).absoluteString,
            "https://meeco.kr/AI/category/38624668"
        )
    }

    func testBoardSearchURLPreservesSelectedCategory() throws {
        XCTAssertEqual(
            MeecoBoard.mini.searchURL(query: "  폴드  ", category: MeecoBoard.mini.categories[1]).absoluteString,
            "https://meeco.kr/mini/category/36923546?search_target=title_content&search_keyword=%ED%8F%B4%EB%93%9C"
        )
    }

    func testParserFiltersMobilePostsBySelectedCategoryQuery() throws {
        let html = """
        <li>
            <a class=\"list_link\" href=\"/mini/41482700?category=36923546\" title=\"음향 게시물\"></a>
        </li>
        <li>
            <a class=\"list_link\" href=\"/mini/41482861?category=23941713\" title=\"미니 게시물\"></a>
        </li>
        <li>
            <a class=\"list_link\" href=\"/mini/15580660?category=36923546\" title=\"음향 공지\"></a>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini/category/36923546")!,
            allowedBoardPaths: ["mini"],
            category: MeecoBoard.mini.categories[1]
        )

        XCTAssertEqual(posts.map(\.title), ["음향 게시물", "음향 공지"])
        XCTAssertEqual(posts.map(\.category), ["36923546", "36923546"])
    }

    func testParserFiltersMiniNoticeTabToVisibleNoticeRows() throws {
        let html = """
        <li>
            <a class=\"list_link\" href=\"/mini/15580660?category=23941775\" title=\"사이트 이용 수칙 241018 수정\"></a>
            <span class=\"notice_text\">공지</span>
            <div class=\"list_title\"><span>사이트 이용 수칙 241018 수정</span></div>
        </li>
        <li class=\"has_cmt\">
            <a class=\"list_link\" href=\"/mini/41482700?category=23941775\" title=\"나노텍스처 다 좋은데 화면 관리가 은근 빡세네요 ㅋㅋ\"></a>
            <span class=\"hot_text\">핫글</span>
            <div class=\"list_title\"><span>나노텍스처 다 좋은데 화면 관리가 은근 빡세네요 ㅋㅋ</span></div>
        </li>
        <li>
            <a class=\"list_link\" href=\"/mini/38706921?category=23941775\" title=\"애플 이벤트 미코 라이브챗(종료)\"></a>
            <div class=\"list_title\"><span class=\"list_ctg\">공지</span>애플 이벤트 미코 라이브챗(종료)</div>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini/category/23941775")!,
            allowedBoardPaths: ["mini"],
            category: MeecoBoard.mini.categories[2]
        )

        XCTAssertEqual(posts.map(\.title), [
            "사이트 이용 수칙 241018 수정",
            "애플 이벤트 미코 라이브챗(종료)"
        ])
    }

    func testParserDoesNotMarkTitleContainingNoticeAsNotice() throws {
        let html = """
        <li class=\"has_cmt\">
            <a class=\"list_link\" href=\"/mini/41490010\" title=\"공지처럼 보이는 일반 글\"></a>
            <div class=\"list_title\">공지처럼 보이는 일반 글</div>
            <div class=\"list_info\"><div><span class=\"member_1\">작성자</span></div><div>1시간 전</div></div>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini")!,
            allowedBoardPaths: ["mini"]
        )

        XCTAssertEqual(posts.first?.title, "공지처럼 보이는 일반 글")
        XCTAssertEqual(posts.first?.isNotice, false)
    }

    func testParserRejectsPromotedRowsInsideCategoryTabs() throws {
        let html = """
        <li class=\"has_cmt\">
            <a class=\"list_link\" href=\"/mini/41482700?category=36923546\" title=\"미니 핫글이 음향 링크로 보임\"></a>
            <span class=\"hot_text\">핫글</span>
            <div class=\"list_title\">미니 핫글이 음향 링크로 보임</div>
        </li>
        <li class=\"has_cmt\">
            <a class=\"list_link\" href=\"/mini/41482701?category=36923546\" title=\"진짜 음향 게시물\"></a>
            <div class=\"list_title\"><span class=\"list_ctg\">음향</span>진짜 음향 게시물</div>
            <div class=\"list_info\"><div><span class=\"member_1\">작성자</span></div><div>1시간 전</div></div>
        </li>
        <li class=\"has_cmt\">
            <a class=\"list_link\" href=\"/mini/41482702?category=36923546\" title=\"미니 게시물이 음향 링크로 보임\"></a>
            <div class=\"list_title\"><span class=\"list_ctg\">미니</span>미니 게시물이 음향 링크로 보임</div>
            <div class=\"list_info\"><div><span class=\"member_2\">작성자</span></div><div>1시간 전</div></div>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini/category/36923546")!,
            allowedBoardPaths: ["mini"],
            category: MeecoBoard.mini.categories[1]
        )

        XCTAssertEqual(posts.map(\.title), ["진짜 음향 게시물"])
    }

    func testParserKeepsPromotedRowsWithExplicitCategoryLink() throws {
        let html = """
        <tr>
            <td class=\"num\">핫글</td>
            <td class=\"category\"><a href=\"/mini/category/23941713\">미니</a></td>
            <td class=\"title\"><a class=\"title_a\" href=\"/mini/41482700\">카테고리 핫글</a></td>
            <td class=\"author\">작성자</td>
            <td class=\"date\">11:14</td>
            <td class=\"readed_count\">613</td>
            <td class=\"voted_count\">10</td>
        </tr>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini/category/23941713")!,
            allowedBoardPaths: ["mini"],
            category: MeecoBoard.mini.categories[0]
        )

        XCTAssertEqual(posts.map(\.title), ["카테고리 핫글"])
        XCTAssertEqual(posts.first?.upvoteCount, 10)
        XCTAssertEqual(posts.first?.isHot, true)
    }

    func testParserAppliesCategoryLabelsAcrossTabbedBoards() throws {
        let html = """
        <li>
            <a class=\"list_link\" href=\"/AI/41490000?category=38624668\" title=\"AI 탭에 섞인 핫글\"></a>
            <span class=\"hot_text\">핫글</span>
            <div class=\"list_title\">AI 탭에 섞인 핫글</div>
        </li>
        <li>
            <a class=\"list_link\" href=\"/AI/41490001?category=38624668\" title=\"실제 로봇 글\"></a>
            <div class=\"list_title\"><span class=\"list_ctg\">로봇</span>실제 로봇 글</div>
        </li>
        <li>
            <a class=\"list_link\" href=\"/AI/41490002?category=38624668\" title=\"AI 글\"></a>
            <div class=\"list_title\"><span class=\"list_ctg\">AI</span>AI 글</div>
        </li>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/AI/category/38624668")!,
            allowedBoardPaths: ["AI"],
            category: MeecoBoard.ai.categories[1]
        )

        XCTAssertEqual(posts.map(\.title), ["실제 로봇 글"])
    }

    func testParserFiltersTableRowsBySelectedCategoryLink() throws {
        let html = """
        <tr>
            <td class=\"category\"><a href=\"/mini/category/36923546\">음향</a></td>
            <td class=\"title\"><a class=\"title_a\" href=\"/mini/41482700\">음향 게시물</a></td>
            <td class=\"author\">작성자</td>
            <td class=\"num\">26.06.06</td>
        </tr>
        <tr>
            <td class=\"category\"><a href=\"/mini/category/23941713\">미니</a></td>
            <td class=\"title\"><a class=\"title_a\" href=\"/mini/41482861\">미니 게시물</a></td>
            <td class=\"author\">작성자</td>
            <td class=\"num\">26.06.06</td>
        </tr>
        """

        let posts = MeecoHTMLParser().posts(
            from: html,
            baseURL: URL(string: "https://meeco.kr/mini/category/36923546")!,
            allowedBoardPaths: ["mini"],
            category: MeecoBoard.mini.categories[1]
        )

        XCTAssertEqual(posts.map(\.title), ["음향 게시물"])
        XCTAssertEqual(posts.first?.category, "음향")
    }

    func testAuthenticatedActionURLsUseMeecoForms() throws {
        XCTAssertEqual(
            MeecoBoard.mini.loginURL().absoluteString,
            "https://meeco.kr/index.php?mid=mini&act=dispMemberLoginForm"
        )
        XCTAssertEqual(
            MeecoBoard.mini.writeURL(category: nil).absoluteString,
            "https://meeco.kr/index.php?mid=mini&act=dispBoardWrite"
        )
        XCTAssertEqual(
            MeecoBoard.mini.writeURL(category: MeecoBoard.mini.categories[1]).absoluteString,
            "https://meeco.kr/index.php?mid=mini&act=dispBoardWrite&category=36923546"
        )

        let post = MeecoPost(
            id: URL(string: "https://meeco.kr/mini/41482340")!,
            documentID: "41482340",
            title: "삼성클라우드 폴드 언팩때 나오려나요",
            nickname: "존버합니다",
            date: "26.06.05",
            url: URL(string: "https://meeco.kr/mini/41482340")!,
            boardPath: "mini",
            category: "미니",
            commentCount: 10,
            upvoteCount: 0,
            isNotice: false,
            isHot: false
        )

        XCTAssertEqual(post.commentURL.absoluteString, "https://meeco.kr/mini/41482340#comment")
    }

    func testParserReadsMeecoLoginFormFields() throws {
        let html = """
        <form action="/" method="POST" class="ff">
            <input type="hidden" name="error_return_url" value="/index.php?mid=mini&amp;act=dispMemberLoginForm" />
            <input type="hidden" name="mid" value="mini" />
            <input type="hidden" name="module" value="member" />
            <input type="hidden" name="act" value="procMemberLogin" />
            <input type="hidden" name="xe_validator_id" value="modules/member/m.skin/default/login_form/1" />
            <input type="text" name="user_id" id="uid" required placeholder="아이디" title="아이디" />
            <input type="password" name="password" id="upw" required placeholder="비밀번호" title="비밀번호" />
            <input type="checkbox" name="keep_signed" id="autoLogin" value="Y" checked="checked" />
            <button type="submit" class="bt_login">로그인</button>
            <a href="/index.php?mid=mini&amp;act=dispMemberSignUpForm">회원가입</a>
            <a href="/index.php?mid=mini&amp;act=dispMemberFindAccount">ID/PW 찾기</a>
        </form>
        """

        let form = try XCTUnwrap(MeecoHTMLParser().loginForm(
            from: html,
            baseURL: URL(string: "https://meeco.kr/index.php?mid=mini&act=dispMemberLoginForm")!
        ))

        XCTAssertEqual(form.actionURL.absoluteString, "https://meeco.kr/")
        XCTAssertEqual(form.method, "POST")
        XCTAssertEqual(form.userIDField, "user_id")
        XCTAssertEqual(form.passwordField, "password")
        XCTAssertEqual(form.keepSignedField, "keep_signed")
        XCTAssertEqual(form.keepSignedDefaultValue, "Y")
        XCTAssertEqual(form.validatorID, "modules/member/m.skin/default/login_form/1")
        XCTAssertEqual(form.signUpURL?.absoluteString, "https://meeco.kr/index.php?mid=mini&act=dispMemberSignUpForm")
        XCTAssertEqual(form.findAccountURL?.absoluteString, "https://meeco.kr/index.php?mid=mini&act=dispMemberFindAccount")
    }

    func testParserLoadsPostDetailContent() throws {
        let post = MeecoPost(
            id: URL(string: "https://meeco.kr/mini/41481365")!,
            documentID: "41481365",
            title: "8.5 상단바 좀 이상하군요",
            nickname: "kty4",
            date: "02:09",
            url: URL(string: "https://meeco.kr/mini/41481365")!,
            boardPath: "mini",
            category: "미니",
            commentCount: 1,
            upvoteCount: 0,
            isNotice: false,
            isHot: false
        )
        let html = """
        <meta property=\"og:title\" content=\"8.5 상단바 좀 이상하군요 - 미코\" />
        <div class=\"xe_content\">
            <p>알림패널 상단은 자연스러운 페이드 아웃이 안되고 딱 잘립니다</p>
            <p>퀵패널은 또 멀쩡하네요</p>
        </div>
        """

        let detail = MeecoHTMLParser().postDetail(from: html, fallbackPost: post)

        XCTAssertEqual(detail.title, "8.5 상단바 좀 이상하군요")
        XCTAssertEqual(detail.nickname, "kty4")
        XCTAssertTrue(detail.body.contains("알림패널 상단"))
        XCTAssertTrue(detail.body.contains("퀵패널"))
    }

    func testParserRemovesHTMLTagsFromPostDetailTitleAndBody() throws {
        let post = MeecoPost(
            id: URL(string: "https://meeco.kr/mini/41482340")!,
            documentID: "41482340",
            title: "삼성클라우드 폴드",
            nickname: "존버합니다",
            date: "26.06.05",
            url: URL(string: "https://meeco.kr/mini/41482340")!,
            boardPath: "mini",
            category: "미니",
            commentCount: nil,
            upvoteCount: 0,
            isNotice: false,
            isHot: false
        )
        let html = """
        <meta property=\"og:title\" content=\"&lt;b&gt;삼성클라우드&lt;/b&gt; 폴드 - 미코\" />
        <div class=\"xe_content\">
            <p>&lt;strong&gt;본문&lt;/strong&gt; 내용입니다</p>
            <p><em>HTML</em> 태그는 보이면 안 됩니다</p>
        </div>
        """

        let detail = MeecoHTMLParser().postDetail(from: html, fallbackPost: post)

        XCTAssertEqual(detail.title, "삼성클라우드 폴드")
        XCTAssertTrue(detail.body.contains("본문 내용입니다"))
        XCTAssertTrue(detail.body.contains("HTML 태그는 보이면 안 됩니다"))
        XCTAssertFalse(detail.title.contains("<") || detail.title.contains(">"))
        XCTAssertFalse(detail.body.contains("<") || detail.body.contains(">"))
    }

    func testParserUsesLongestTitleOnceAndRemovesItFromBodyStart() throws {
        let post = MeecoPost(
            id: URL(string: "https://meeco.kr/mini/41482340")!,
            documentID: "41482340",
            title: "짧은 제목",
            nickname: "존버합니다",
            date: "26.06.05",
            url: URL(string: "https://meeco.kr/mini/41482340")!,
            boardPath: "mini",
            category: "미니",
            commentCount: nil,
            upvoteCount: 0,
            isNotice: false,
            isHot: false
        )
        let html = """
        <meta property=\"og:title\" content=\"삼성클라우드 폴드 언팩때 나오려나요 - 미코\" />
        <h1>삼성클라우드</h1>
        <article>
            <h1>삼성클라우드 폴드 언팩때 나오려나요</h1>
            <div class=\"xe_content\">
                <p>본문 첫 줄입니다</p>
                <p>본문 둘째 줄입니다</p>
            </div>
        </article>
        """

        let detail = MeecoHTMLParser().postDetail(from: html, fallbackPost: post)

        XCTAssertEqual(detail.title, "삼성클라우드 폴드 언팩때 나오려나요")
        XCTAssertTrue(detail.body.hasPrefix("본문 첫 줄입니다"))
        XCTAssertFalse(detail.body.hasPrefix(detail.title))
    }

    func testParserPreservesPostParagraphSpacing() throws {
        let post = MeecoPost(
            id: URL(string: "https://meeco.kr/mini/41482342")!,
            documentID: "41482342",
            title: "문단 간격 테스트",
            nickname: "작성자",
            date: "26.06.05",
            url: URL(string: "https://meeco.kr/mini/41482342")!,
            boardPath: "mini",
            category: "미니",
            commentCount: nil,
            upvoteCount: 0,
            isNotice: false,
            isHot: false
        )
        let html = """
        <meta property=\"og:title\" content=\"문단 간격 테스트 - 미코\" />
        <div class=\"xe_content\">
            <p>첫 번째 문단입니다</p>
            <p>두 번째 문단입니다<br />줄바꿈입니다</p>
        </div>
        """

        let detail = MeecoHTMLParser().postDetail(from: html, fallbackPost: post)

        XCTAssertEqual(detail.body, "첫 번째 문단입니다\n\n두 번째 문단입니다\n줄바꿈입니다")
    }

    func testParserExtractsPostImagesAndCommentImages() throws {
        let post = MeecoPost(
            id: URL(string: "https://meeco.kr/mini/41482343")!,
            documentID: "41482343",
            title: "사진 테스트",
            nickname: "작성자",
            date: "26.06.05",
            url: URL(string: "https://meeco.kr/mini/41482343")!,
            boardPath: "mini",
            category: "미니",
            commentCount: nil,
            upvoteCount: 0,
            isNotice: false,
            isHot: false
        )
        let html = """
        <meta property=\"og:title\" content=\"사진 테스트 - 미코\" />
        <div class=\"document_41482343_1 rhymix_content xe_content\">
            <p>본문 사진입니다</p>
            <p><img src=\"/files/attach/images/123/photo.heic\" alt=\"HDR 사진\" /></p>
            <p><img data-src=\"/files/attach/images/123/lazy.webp\" alt=\"lazy\" /></p>
            <p><a href=\"/files/attach/images/123/movie.mp4\">동영상</a></p>
            <p><a href=\"https://www.youtube.com/watch?v=dQw4w9WgXcQ\">유튜브</a></p>
            <p><a href=\"https://x.com/meeco/status/1\">X 링크</a></p>
            <p><a href=\"https://www.instagram.com/p/example/\">Instagram 링크</a></p>
            <p><a href=\"https://www.threads.net/@meeco/post/example\">Threads 링크</a></p>
        </div>
        <article class=\"cmt_unit\" id=\"comment_41482355\">
            <header><spanclass=\"bt_cmt_ctrl3 nickname member_38635502\">digi</span><span class=\"date\">26.06.05 10:00</span></header>
            <div class=\"comment_41482355_38635502 rhymix_content xe_content\">
                <p>댓글 사진입니다</p>
                <p><img src=\"/files/attach/images/123/comment.jpg\" alt=\"댓글 사진\" /></p>
            </div>
            <span class=\"cmt_vote_up\"><i class=\"xi-heart\"></i> <b class=\"num\">12</b></span>
        </article>
        """

        let detail = MeecoHTMLParser().postDetail(from: html, fallbackPost: post)

        XCTAssertEqual(detail.media.map(\.url.absoluteString), [
            "https://meeco.kr/files/attach/images/123/photo.heic",
            "https://meeco.kr/files/attach/images/123/lazy.webp",
            "https://meeco.kr/files/attach/images/123/movie.mp4",
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "https://x.com/meeco/status/1",
            "https://www.instagram.com/p/example/",
            "https://www.threads.net/@meeco/post/example"
        ])
        XCTAssertEqual(detail.media.map(\.kind), [.image, .image, .video, .linkPreview, .linkPreview, .linkPreview, .linkPreview])
        XCTAssertEqual(detail.media.first?.altText, "HDR 사진")
        XCTAssertEqual(detail.comments.count, 1)
        XCTAssertEqual(detail.comments.first?.nickname, "digi")
        XCTAssertEqual(detail.comments.first?.upvoteCount, 12)
        XCTAssertTrue(detail.comments.first?.body.contains("댓글 사진입니다") == true)
        XCTAssertEqual(detail.comments.first?.media.map(\.url.absoluteString), ["https://meeco.kr/files/attach/images/123/comment.jpg"])
    }

    func testParserMarksReplyCommentsWithDepth() throws {
        let post = MeecoPost(
            id: URL(string: "https://meeco.kr/mini/41484658")!,
            documentID: "41484658",
            title: "댓글 계층 테스트",
            nickname: "작성자",
            date: "26.06.07",
            url: URL(string: "https://meeco.kr/mini/41484658")!,
            boardPath: "mini",
            category: "미니",
            commentCount: nil,
            upvoteCount: 0,
            isNotice: false,
            isHot: false
        )
        let html = """
        <article class=\"cmt_unit\" id=\"comment_1\">
            <header><spanclass=\"bt_cmt_ctrl3 nickname member_1\">원댓글</span><span class=\"date\">26.06.07 10:00</span></header>
            <!--BeforeComment(1,1)--><div class=\"comment_1_1 rhymix_content xe_content\"><p>첫 댓글입니다 reply 버튼이 있어도 원댓글입니다</p></div><!--AfterComment(1,1)-->
        </article>
        <article class=\"cmt_unit reply\" id=\"comment_2\">
            <i class=\"xi-subdirectory icon_reply\"></i>
            <header><spanclass=\"bt_cmt_ctrl3 nickname member_2\">답글</span><span class=\"date\">26.06.07 10:10</span></header>
            <div class=\"cmt_to\"><span>@원댓글</span></div>
            <!--BeforeComment(2,2)--><div class=\"comment_2_2 rhymix_content xe_content\"><p>이어지는 답글입니다</p></div><!--AfterComment(2,2)-->
        </article>
        <article class=\"cmt_unit reply\" id=\"comment_3\">
            <i class=\"xi-subdirectory icon_reply\"></i>
            <header><spanclass=\"bt_cmt_ctrl3 nickname member_3\">작성자</span><span class=\"date\">26.06.07 10:20</span></header>
            <div class=\"cmt_to\"><span>@답글</span></div>
            <!--BeforeComment(3,3)--><div class=\"comment_3_3 rhymix_content xe_content\"><p>답글에 이어지는 재답글입니다</p></div><!--AfterComment(3,3)-->
        </article>
        """

        let detail = MeecoHTMLParser().postDetail(from: html, fallbackPost: post)

        XCTAssertEqual(detail.comments.map(\.body), ["첫 댓글입니다 reply 버튼이 있어도 원댓글입니다", "이어지는 답글입니다", "답글에 이어지는 재답글입니다"])
        XCTAssertEqual(detail.comments.map(\.replyDepth), [0, 1, 2])
        XCTAssertEqual(detail.comments.map(\.isPostAuthor), [false, false, true])
    }

    func testParserReadsOnlyActualCommentSection() throws {
        let post = MeecoPost(
            id: URL(string: "https://meeco.kr/mini/41484658")!,
            documentID: "41484658",
            title: "댓글 영역 테스트",
            nickname: "작성자",
            date: "26.06.07",
            url: URL(string: "https://meeco.kr/mini/41484658")!,
            boardPath: "mini",
            category: "미니",
            commentCount: nil,
            upvoteCount: 0,
            isNotice: false,
            isHot: false
        )
        let html = """
        <article class=\"cmt_unit reply\" id=\"comment_fake\">
            <!--BeforeComment(0,0)--><div class=\"comment_0_0 xe_content\"><p>댓글 영역 밖입니다</p></div><!--AfterComment(0,0)-->
        </article>
        <div id=\"comment\" class=\"cmt\">
            <article class=\"cmt_unit\" id=\"comment_1\">
                <header><spanclass=\"bt_cmt_ctrl3 nickname member_1\">원댓글</span></header>
                <!--BeforeComment(1,1)--><div class=\"comment_1_1 xe_content\"><p>진짜 댓글입니다</p></div><!--AfterComment(1,1)-->
            </article>
        </div>
        <div class=\"list_d\">
            <article class=\"cmt_unit reply\" id=\"comment_list_fake\">
                <!--BeforeComment(2,2)--><div class=\"comment_2_2 xe_content\"><p>목록 영역입니다</p></div><!--AfterComment(2,2)-->
            </article>
        </div>
        """

        let detail = MeecoHTMLParser().postDetail(from: html, fallbackPost: post)

        XCTAssertEqual(detail.comments.map(\.body), ["진짜 댓글입니다"])
        XCTAssertEqual(detail.comments.map(\.replyDepth), [0])
    }

    @MainActor
    func testBoardViewModelPromptsBeforeApplyingLatestFirstPagePosts() async throws {
        var callCount = 0
        let service = MeecoService(boardSnapshotFetcher: { _, page, _ in
            callCount += 1
            let posts = callCount == 1
                ? [Self.post(documentID: "1", title: "이전 글")]
                : [Self.post(documentID: "2", title: "최신 글"), Self.post(documentID: "1", title: "이전 글")]
            return MeecoBoardSnapshot(posts: posts, page: page, sourceFingerprint: callCount, fetchedAt: Date())
        })
        let viewModel = BoardViewModel(board: .mini, service: service)

        await viewModel.load()
        XCTAssertEqual(viewModel.posts.map(\.title), ["이전 글"])

        await viewModel.checkForLatestPosts()
        XCTAssertTrue(viewModel.hasPendingLatestPosts)
        XCTAssertTrue(viewModel.shouldPromptForUpdate)
        XCTAssertEqual(viewModel.pendingLatestPostCount, 1)
        XCTAssertEqual(viewModel.posts.map(\.title), ["이전 글"])

        await viewModel.applyLatestPosts()
        XCTAssertFalse(viewModel.hasPendingLatestPosts)
        XCTAssertFalse(viewModel.shouldPromptForUpdate)
        XCTAssertEqual(viewModel.pendingLatestPostCount, 0)
        XCTAssertEqual(viewModel.refreshStatusMessage, "새 게시물 1개를 불러왔습니다.")
        XCTAssertEqual(viewModel.posts.map(\.title), ["최신 글", "이전 글"])
    }

    @MainActor
    func testBoardViewModelRefreshKeepsAuthorAndDateForNewPosts() async throws {
        var callCount = 0
        let service = MeecoService(boardSnapshotFetcher: { _, page, _ in
            callCount += 1
            let posts = callCount == 1
                ? [Self.post(documentID: "1", title: "이전 글")]
                : [
                    Self.post(documentID: "2", title: "새 글", nickname: "새작성자", date: "26.06.06"),
                    Self.post(documentID: "1", title: "이전 글")
                ]
            return MeecoBoardSnapshot(posts: posts, page: page, sourceFingerprint: callCount, fetchedAt: Date())
        })
        let viewModel = BoardViewModel(board: .mini, service: service)

        await viewModel.load()
        await viewModel.applyLatestPosts()

        XCTAssertEqual(viewModel.posts.first?.title, "새 글")
        XCTAssertEqual(viewModel.posts.first?.nickname, "새작성자")
        XCTAssertEqual(viewModel.posts.first?.date, "26.06.06")
    }

    @MainActor
    func testBoardViewModelRefreshUpdatesAuthorAndDateWhenThereAreNoNewPosts() async throws {
        var callCount = 0
        let service = MeecoService(boardSnapshotFetcher: { _, page, _ in
            callCount += 1
            let posts = callCount == 1
                ? [Self.post(documentID: "1", title: "현재 글", nickname: "", date: "")]
                : [Self.post(documentID: "1", title: "현재 글", nickname: "작성자", date: "26.06.07.")]
            return MeecoBoardSnapshot(posts: posts, page: page, sourceFingerprint: callCount, fetchedAt: Date())
        })
        let viewModel = BoardViewModel(board: .mini, service: service)

        await viewModel.load()
        await viewModel.applyLatestPosts()

        XCTAssertEqual(viewModel.refreshStatusMessage, "새 게시물이 없습니다.")
        XCTAssertEqual(viewModel.posts.map(\.title), ["현재 글"])
        XCTAssertEqual(viewModel.posts.first?.nickname, "작성자")
        XCTAssertEqual(viewModel.posts.first?.date, "26.06.07.")
    }

    @MainActor
    func testBoardViewModelDoesNotPromptWhenExistingListMayBeStaleButCurrent() async throws {
        let service = MeecoService(boardSnapshotFetcher: { _, page, _ in
            MeecoBoardSnapshot(
                posts: [Self.post(documentID: "1", title: "현재 글")],
                page: page,
                sourceFingerprint: 1,
                fetchedAt: Date()
            )
        })
        let viewModel = BoardViewModel(board: .mini, service: service)

        await viewModel.load()
        XCTAssertFalse(viewModel.shouldPromptForUpdate)

        viewModel.markListMayBeStale()
        XCTAssertFalse(viewModel.shouldPromptForUpdate)

        await viewModel.applyLatestPosts()
        XCTAssertFalse(viewModel.shouldPromptForUpdate)
        XCTAssertEqual(viewModel.refreshStatusMessage, "새 게시물이 없습니다.")
        XCTAssertEqual(viewModel.posts.map(\.title), ["현재 글"])
    }

    @MainActor
    func testBoardViewModelDoesNotPromptForLatestCheckWithoutLeadingNewPosts() async throws {
        var callCount = 0
        let service = MeecoService(boardSnapshotFetcher: { _, page, _ in
            callCount += 1
            let posts = callCount == 1
                ? [Self.post(documentID: "1", title: "현재 글"), Self.post(documentID: "2", title: "이전 글")]
                : [Self.post(documentID: "2", title: "이전 글"), Self.post(documentID: "1", title: "현재 글")]
            return MeecoBoardSnapshot(posts: posts, page: page, sourceFingerprint: callCount, fetchedAt: Date())
        })
        let viewModel = BoardViewModel(board: .mini, service: service)

        await viewModel.load()
        await viewModel.checkForLatestPosts()

        XCTAssertFalse(viewModel.hasPendingLatestPosts)
        XCTAssertFalse(viewModel.shouldPromptForUpdate)
        XCTAssertEqual(viewModel.pendingLatestPostCount, 0)
    }

    @MainActor
    func testBoardViewModelRefreshDoesNotReplaceListWhenThereAreNoNewPosts() async throws {
        var callCount = 0
        let service = MeecoService(boardSnapshotFetcher: { _, page, _ in
            callCount += 1
            let posts = callCount == 1
                ? [Self.post(documentID: "1", title: "현재 글"), Self.post(documentID: "2", title: "이전 글")]
                : [Self.post(documentID: "2", title: "이전 글"), Self.post(documentID: "1", title: "현재 글")]
            return MeecoBoardSnapshot(posts: posts, page: page, sourceFingerprint: callCount, fetchedAt: Date())
        })
        let viewModel = BoardViewModel(board: .mini, service: service)

        await viewModel.load()
        XCTAssertEqual(viewModel.posts.map(\.title), ["현재 글", "이전 글"])

        await viewModel.applyLatestPosts()
        XCTAssertEqual(viewModel.refreshStatusMessage, "새 게시물이 없습니다.")
        XCTAssertEqual(viewModel.posts.map(\.title), ["현재 글", "이전 글"])
    }

    @MainActor
    func testBoardViewModelRefreshCountsOnlyLeadingNewPosts() async throws {
        var callCount = 0
        let service = MeecoService(boardSnapshotFetcher: { _, page, _ in
            callCount += 1
            let posts = callCount == 1
                ? [Self.post(documentID: "1", title: "현재 글"), Self.post(documentID: "2", title: "이전 글")]
                : [
                    Self.post(documentID: "3", title: "새 글"),
                    Self.post(documentID: "4", title: "더 새 글"),
                    Self.post(documentID: "1", title: "현재 글"),
                    Self.post(documentID: "2", title: "이전 글")
                ]
            return MeecoBoardSnapshot(posts: posts, page: page, sourceFingerprint: callCount, fetchedAt: Date())
        })
        let viewModel = BoardViewModel(board: .mini, service: service)

        await viewModel.load()
        await viewModel.checkForLatestPosts()

        XCTAssertEqual(viewModel.pendingLatestPostCount, 2)

        await viewModel.applyLatestPosts()

        XCTAssertEqual(viewModel.refreshStatusMessage, "새 게시물 2개를 불러왔습니다.")
        XCTAssertEqual(viewModel.posts.map(\.title), ["새 글", "더 새 글", "현재 글", "이전 글"])
    }

    @MainActor
    func testBoardViewModelRefreshDoesNotReportWholePageWhenCurrentFirstIsMissing() async throws {
        var callCount = 0
        let service = MeecoService(boardSnapshotFetcher: { _, page, _ in
            callCount += 1
            let posts = callCount == 1
                ? [Self.post(documentID: "1", title: "현재 글")]
                : [
                    Self.post(documentID: "10", title: "다른 탭 글 1"),
                    Self.post(documentID: "11", title: "다른 탭 글 2")
                ]
            return MeecoBoardSnapshot(posts: posts, page: page, sourceFingerprint: callCount, fetchedAt: Date())
        })
        let viewModel = BoardViewModel(board: .mini, service: service)

        await viewModel.load()
        await viewModel.applyLatestPosts()

        XCTAssertEqual(viewModel.refreshStatusMessage, "새 게시물이 없습니다.")
        XCTAssertEqual(viewModel.posts.map(\.title), ["현재 글"])
    }

    @MainActor
    func testBoardViewModelCategorySelectionForcesLoadWhilePreviousLoadIsRunning() async throws {
        var callCount = 0
        let service = MeecoService(boardSnapshotFetcher: { _, page, category in
            callCount += 1
            if callCount == 1 {
                try await Task.sleep(nanoseconds: 200_000_000)
                return MeecoBoardSnapshot(
                    posts: [Self.post(documentID: "1", title: "전체 글")],
                    page: page,
                    sourceFingerprint: 1,
                    fetchedAt: Date()
                )
            }

            return MeecoBoardSnapshot(
                posts: [Self.post(documentID: "2", title: "\(category?.title ?? "선택") 글")],
                page: page,
                sourceFingerprint: 2,
                fetchedAt: Date()
            )
        })
        let viewModel = BoardViewModel(board: .mini, service: service)

        let initialLoad = Task { await viewModel.load() }
        try await Task.sleep(nanoseconds: 50_000_000)
        await viewModel.selectCategory(MeecoBoard.mini.categories[0])
        await initialLoad.value

        XCTAssertEqual(viewModel.selectedCategory?.title, "미니")
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.posts.map(\.title), ["미니 글"])
    }

    @MainActor
    func testBoardViewModelTopUpvotedPostsReturnsHighestThree() async throws {
        let service = MeecoService(boardSnapshotFetcher: { _, page, _ in
            MeecoBoardSnapshot(
                posts: [
                    Self.post(documentID: "1", title: "낮은 추천", upvoteCount: 1),
                    Self.post(documentID: "2", title: "최고 추천", upvoteCount: 9),
                    Self.post(documentID: "3", title: "추천 없음", upvoteCount: 0),
                    Self.post(documentID: "4", title: "중간 추천", upvoteCount: 5),
                    Self.post(documentID: "5", title: "세번째 추천", upvoteCount: 3)
                ],
                page: page,
                sourceFingerprint: 1,
                fetchedAt: Date()
            )
        })
        let viewModel = BoardViewModel(board: .mini, service: service)

        await viewModel.load()

        XCTAssertEqual(viewModel.topUpvotedPosts.map(\.title), ["최고 추천", "중간 추천", "세번째 추천"])
    }

    private static func post(documentID: String, title: String, nickname: String = "작성자", date: String = "26.06.05", upvoteCount: Int = 0) -> MeecoPost {
        MeecoPost(
            id: URL(string: "https://meeco.kr/mini/\(documentID)")!,
            documentID: documentID,
            title: title,
            nickname: nickname,
            date: date,
            url: URL(string: "https://meeco.kr/mini/\(documentID)")!,
            boardPath: "mini",
            category: "미니",
            commentCount: nil,
            upvoteCount: upvoteCount,
            isNotice: false,
            isHot: false
        )
    }
}
