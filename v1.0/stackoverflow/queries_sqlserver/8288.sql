
WITH UserBadgeCounts AS (
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
TopUsersByReputation AS (
    SELECT TOP 10 
        Id,
        DisplayName,
        Reputation
    FROM Users
    ORDER BY Reputation DESC
),
PostEngagement AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    WHERE P.CreationDate >= DATEADD(year, -1, CAST('2024-10-01 12:34:56' AS DATETIME))
    GROUP BY P.OwnerUserId
)
SELECT 
    U.DisplayName,
    T.Reputation,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    PE.PostCount,
    PE.TotalViews,
    PE.TotalScore
FROM UserBadgeCounts U
JOIN PostEngagement PE ON U.UserId = PE.OwnerUserId
JOIN TopUsersByReputation T ON U.UserId = T.Id
ORDER BY T.Reputation DESC, U.BadgeCount DESC;
