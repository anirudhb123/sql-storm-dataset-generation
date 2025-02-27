WITH RecursiveCTE AS (
    SELECT Id, Title, ViewCount, Score, AcceptedAnswerId, ParentId, 
           1 AS Level
    FROM Posts
    WHERE PostTypeId = 1 -- Starting from questions
    UNION ALL
    SELECT p.Id, p.Title, p.ViewCount, p.Score, p.AcceptedAnswerId, p.ParentId,
           rc.Level + 1
    FROM Posts p
    INNER JOIN RecursiveCTE rc ON p.ParentId = rc.Id
),
AggregatedScores AS (
    SELECT p.OwnerUserId,
           COUNT(*) AS NumberOfPosts,
           SUM(p.ViewCount) AS TotalViews,
           AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY p.OwnerUserId
),
UserBadges AS (
    SELECT u.Id AS UserId,
           COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT u.Id AS UserId,
       u.DisplayName,
       ua.NumberOfPosts,
       ua.TotalViews,
       ua.AverageBounty,
       ub.GoldBadges,
       ub.SilverBadges,
       ub.BronzeBadges,
       CASE 
           WHEN ua.TotalViews > 1000 AND ub.GoldBadges > 0 THEN 'Top Contributor'
           WHEN ua.TotalViews > 500 THEN 'Active Contributor'
           ELSE 'New Contributor'
       END AS ContributorLevel,
       r.Level AS PostChainLevel
FROM Users u
LEFT JOIN AggregatedScores ua ON u.Id = ua.OwnerUserId 
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN RecursiveCTE r ON r.AcceptedAnswerId = u.Id
WHERE (ua.TotalViews IS NOT NULL OR ub.GoldBadges > 0)
  AND u.Reputation > 100 
ORDER BY ua.TotalViews DESC, ub.GoldBadges DESC;
