WITH UserBadges AS (
    SELECT
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PopularPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount
    HAVING COUNT(C.Id) > 5 OR COUNT(V.Id) > 5
),
PostHistorySummary AS (
    SELECT
        PH.PostId,
        MAX(PH.CreationDate) AS LastEdited,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS Closed
    FROM PostHistory PH
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PP.Title,
    PP.Score,
    PP.ViewCount,
    PP.CommentCount,
    PHS.LastEdited,
    PHS.EditCount,
    CASE WHEN PHS.Closed > 0 THEN 'Yes' ELSE 'No' END AS IsClosed
FROM UserBadges UB
JOIN Users U ON U.Id = UB.UserId
JOIN PopularPosts PP ON U.Id = PP.OwnerUserId
JOIN PostHistorySummary PHS ON PP.PostId = PHS.PostId
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC, PP.Score DESC;
