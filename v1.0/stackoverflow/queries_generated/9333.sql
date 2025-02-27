WITH UserBadges AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           COUNT(B.Id) AS BadgeCount, 
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
TopPosts AS (
    SELECT P.Id AS PostId, 
           P.Title, 
           P.OwnerUserId, 
           P.CreationDate,
           P.Score, 
           RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM Posts P
    WHERE P.PostTypeId = 1
),
UserPostStats AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           COALESCE(TP.PostCount, 0) AS PostCount, 
           COALESCE(TP.AverageScore, 0) AS AverageScore
    FROM Users U
    LEFT JOIN (
        SELECT OwnerUserId, 
               COUNT(Id) AS PostCount, 
               AVG(Score) AS AverageScore
        FROM Posts
        WHERE PostTypeId = 1
        GROUP BY OwnerUserId
    ) AS TP ON U.Id = TP.OwnerUserId
),
FinalStats AS (
    SELECT U.DisplayName, 
           UB.BadgeCount, 
           UB.GoldCount, 
           UB.SilverCount, 
           UB.BronzeCount, 
           UPS.PostCount, 
           UPS.AverageScore
    FROM UserBadges UB
    JOIN UserPostStats UPS ON UB.UserId = UPS.UserId
)
SELECT * 
FROM FinalStats
WHERE BadgeCount > 0 AND PostCount > 5
ORDER BY AverageScore DESC, BadgeCount DESC
LIMIT 10;
