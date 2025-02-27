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
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        AVG(V.VoteTypeId) AS AverageVote
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.PostTypeId = 1
    GROUP BY P.Id, P.Title, P.ViewCount, P.OwnerUserId
),
RankedPosts AS (
    SELECT 
        PP.PostId,
        PP.Title,
        PP.ViewCount,
        PP.CommentCount,
        PP.AverageVote,
        RANK() OVER (ORDER BY PP.ViewCount DESC) AS ViewRank
    FROM PopularPosts PP
)
SELECT 
    UB.DisplayName,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    RP.Title,
    RP.ViewCount,
    RP.CommentCount,
    RP.AverageVote,
    RP.ViewRank
FROM UserBadges UB
JOIN RankedPosts RP ON UB.UserId = RP.OwnerUserId
WHERE UB.BadgeCount > 5 AND RP.ViewRank <= 10
ORDER BY RP.ViewCount DESC;

