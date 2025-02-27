WITH RECURSIVE HighScoreUsers AS (
    SELECT Id, DisplayName, Reputation,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
    WHERE Reputation > 1000
),
UserBadges AS (
    SELECT b.UserId, 
           COUNT(b.Id) AS TotalBadges,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostStats AS (
    SELECT p.OwnerUserId,
           COUNT(p.Id) AS TotalPosts,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           SUM(p.ViewCount) AS TotalViews,
           AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserReputation AS (
    SELECT u.Id AS UserId,
           COALESCE(bs.TotalBadges, 0) AS TotalBadges,
           COALESCE(ps.TotalPosts, 0) AS TotalPosts,
           COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
           COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
           COALESCE(ps.TotalViews, 0) AS TotalViews,
           COALESCE(ps.AverageScore, 0) AS AverageScore,
           u.Reputation
    FROM Users u
    LEFT JOIN UserBadges bs ON u.Id = bs.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
),
FinalResults AS (
    SELECT u.Id, 
           u.DisplayName,
           u.Reputation,
           u.TotalBadges,
           u.TotalPosts,
           u.TotalQuestions,
           u.TotalAnswers,
           u.TotalViews,
           u.AverageScore,
           CASE 
               WHEN u.Reputation >= 10000 THEN 'Top Contributor'
               WHEN u.Reputation >= 5000 THEN 'Established Contributor'
               ELSE 'New Contributor'
           END AS ContributorLevel
    FROM UserReputation u
)
SELECT f.DisplayName,
       f.Reputation,
       f.TotalBadges,
       f.TotalPosts,
       f.TotalQuestions,
       f.TotalAnswers,
       f.TotalViews,
       f.AverageScore,
       f.ContributorLevel,
       RANK() OVER (ORDER BY f.Reputation DESC) AS OverallRank
FROM FinalResults f
JOIN HighScoreUsers h ON f.Id = h.Id
ORDER BY f.Reputation DESC, f.TotalPosts DESC
LIMIT 10;
