WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostsWithAnswers AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.AcceptedAnswerId,
        P.CreationDate,
        COUNT(DISTINCT CASE WHEN P2.Id IS NOT NULL THEN P2.Id END) AS AnswerCount,
        COALESCE(MAX(P2.ViewCount), 0) AS MaxViewCount
    FROM Posts P
    LEFT JOIN Posts P2 ON P.Id = P2.ParentId
    WHERE P.PostTypeId = 1
    GROUP BY P.Id, P.Title, P.AcceptedAnswerId, P.CreationDate
),
PostsHistoryClosure AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.PostId
),
RankedPosts AS (
    SELECT 
        PWA.PostId,
        ROW_NUMBER() OVER (PARTITION BY UBD.UserId ORDER BY PWA.MaxViewCount DESC, PWA.AnswerCount DESC) AS Rank
    FROM PostsWithAnswers PWA
    JOIN UserBadges UBD ON PWA.AcceptedAnswerId IS NOT NULL
    JOIN Users U ON U.Id = PWA.AcceptedAnswerId
    WHERE UBD.BadgeCount >= 5 AND PWA.MaxViewCount > 0
)
SELECT 
    UBD.DisplayName,
    PWA.Title,
    PWA.CreationDate,
    COALESCE(PHC.ClosureCount, 0) AS ClosureCount,
    RP.Rank
FROM RankedPosts RP
JOIN PostsWithAnswers PWA ON RP.PostId = PWA.PostId
JOIN UserBadges UBD ON RP.UserId = UBD.UserId
LEFT JOIN PostsHistoryClosure PHC ON PWA.PostId = PHC.PostId
WHERE RP.Rank <= 10
ORDER BY RP.Rank, PWA.CreationDate DESC;

This query combines various advanced SQL constructs, including Common Table Expressions (CTEs) for organizing and querying complex data. It retrieves users with a significant number of badges and ranks their posts based on their view counts and answer counts while also checking for post closures in the history. The final selection filters to the top-ranked posts, demonstrating skills in outer joins, aggregations, window functions, and correlated subqueries.
