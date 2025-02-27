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
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AvgScore,
        MAX(P.ViewCount) AS MaxViewCount,
        MIN(P.CreationDate) AS FirstPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11)
),
PopularPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AcceptedAnswerId,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS PopularityRank
    FROM Posts P
    WHERE P.PostTypeId = 1
    AND (P.AcceptedAnswerId IS NOT NULL OR P.AnswerCount > 0)
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    PS.PostCount,
    COALESCE(RPH.CreationDate, 'No Close Reason') AS LastActionDate,
    PP.Title AS PopularPostTitle,
    PP.Score AS PopularPostScore,
    PP.ViewCount AS PopularPostViewCount
FROM UserBadges U
LEFT JOIN PostStats PS ON U.UserId = PS.OwnerUserId
LEFT JOIN RecentPostHistory RPH ON U.UserId = RPH.UserId AND RPH.rn = 1
LEFT JOIN PopularPosts PP ON U.UserId = PP.OwnerUserId
WHERE U.BadgeCount > 0
AND (PS.PostCount > 5 OR U.Reputation > 100)
ORDER BY U.Reputation DESC, U.BadgeCount DESC
LIMIT 10;

-- Ensure that corner cases where a user has no active posts 
-- or badges are properly handled by utilizing COALESCE,
-- while maintaining performance with efficient joins and CTEs.
