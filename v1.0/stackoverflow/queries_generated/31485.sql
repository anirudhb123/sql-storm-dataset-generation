WITH RECURSIVE TopUsers AS (
    SELECT Id, DisplayName, Reputation, CreationDate
    FROM Users
    WHERE Reputation > 1000
    UNION ALL
    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate
    FROM Users u
    INNER JOIN TopUsers tu ON u.Reputation > tu.Reputation
    WHERE u.Id != tu.Id
),
BadgedUsers AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount 
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT p.OwnerUserId, COUNT(p.Id) AS TotalPosts, 
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           AVG(p.Score) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPostStats AS (
    SELECT u.DisplayName, u.Reputation, pu.TotalPosts, pu.Questions, pu.Answers, pu.AvgScore,
           COALESCE(bu.BadgeCount, 0) AS BadgeCount
    FROM Users u
    LEFT JOIN PostStats pu ON u.Id = pu.OwnerUserId
    LEFT JOIN BadgedUsers bu ON u.Id = bu.UserId
)

SELECT ups.DisplayName, ups.Reputation, ups.TotalPosts, 
       ups.Questions, ups.Answers, ups.AvgScore, ups.BadgeCount,
       CASE 
           WHEN ups.Reputation IS NULL THEN 'No Reputation'
           WHEN ups.Reputation >= 10000 THEN 'Top Rated'
           ELSE 'Average User'
       END AS UserStatus,
       CASE
           WHEN ups.TotalPosts IS NULL THEN NULL
           ELSE ROUND(ups.AvgScore * 1.0 / ups.TotalPosts, 2)
       END AS AvgScorePerPost
FROM UserPostStats ups
FULL OUTER JOIN TopUsers tu ON ups.DisplayName = tu.DisplayName
WHERE ups.TotalPosts IS NOT NULL OR ups.BadgeCount > 0
ORDER BY ups.Reputation DESC, ups.TotalPosts DESC;
