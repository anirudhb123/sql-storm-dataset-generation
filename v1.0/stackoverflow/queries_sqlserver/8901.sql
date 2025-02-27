
WITH TopUsers AS (
    SELECT Id, DisplayName, Reputation
    FROM Users
    WHERE Reputation > 5000
    ORDER BY Reputation DESC
    OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
), UserPostCounts AS (
    SELECT OwnerUserId, COUNT(*) AS PostCount
    FROM Posts
    WHERE CreationDate >= CAST('2024-10-01' AS DATE) - DATEADD(YEAR, 1, 0)
    GROUP BY OwnerUserId
), UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    WHERE Date >= CAST('2024-10-01' AS DATE) - DATEADD(YEAR, 1, 0)
    GROUP BY UserId
), UserScores AS (
    SELECT u.Id AS UserId, u.DisplayName, COALESCE(UPC.PostCount, 0) AS PostCount, COALESCE(UB.BadgeCount, 0) AS BadgeCount
    FROM TopUsers u
    LEFT JOIN UserPostCounts UPC ON u.Id = UPC.OwnerUserId
    LEFT JOIN UserBadges UB ON u.Id = UB.UserId
)
SELECT u.UserId, u.DisplayName, u.PostCount, u.BadgeCount
FROM UserScores u
JOIN (
    SELECT UserId, SUM(DISTINCT Score) AS TotalScore
    FROM Posts
    JOIN Votes ON Posts.Id = Votes.PostId
    GROUP BY UserId
) v ON u.UserId = v.UserId
ORDER BY u.PostCount DESC, v.TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
