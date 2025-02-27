
WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    WHERE Class = 1 
    GROUP BY UserId
),
PostScoreStats AS (
    SELECT OwnerUserId, AVG(Score) AS AvgScore, SUM(ViewCount) AS TotalViews
    FROM Posts
    WHERE CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY OwnerUserId
),
ActiveUsers AS (
    SELECT U.Id, U.DisplayName, U.Reputation, U.CreationDate, 
           COALESCE(UB.BadgeCount, 0) AS GoldBadgeCount,
           COALESCE(PSS.AvgScore, 0) AS AvgScore, 
           COALESCE(PSS.TotalViews, 0) AS TotalViews
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostScoreStats PSS ON U.Id = PSS.OwnerUserId
    WHERE U.Reputation > 1000 
      AND U.LastAccessDate >= DATEADD(MONTH, -6, '2024-10-01 12:34:56')
),
TopPosts AS (
    SELECT P.Id, P.Title, P.OwnerUserId, P.Score
    FROM Posts P
    WHERE P.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56') 
      AND P.Score > 0
    ORDER BY P.Score DESC
)
SELECT AU.DisplayName, AU.Reputation, AU.GoldBadgeCount, AU.AvgScore,
       AU.TotalViews, TP.Title, TP.Score
FROM ActiveUsers AU
JOIN TopPosts TP ON AU.Id = TP.OwnerUserId
ORDER BY AU.Reputation DESC, TP.Score DESC;
