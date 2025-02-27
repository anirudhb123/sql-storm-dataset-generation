WITH RecursivePostHierarchy AS (
    -- CTE to retrieve all posts along with their accepted answers
    SELECT p.Id AS PostId, p.AcceptedAnswerId, 1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Questions
    UNION ALL
    SELECT p.Id, p.AcceptedAnswerId, Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.Id = r.AcceptedAnswerId
),
UserReputationSummary AS (
    -- CTE to summarize user reputation and their associated badges
    SELECT u.Id AS UserId, 
           u.Reputation,
           COUNT(b.Id) AS BadgeCount,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
PostMetrics AS (
    -- CTE to calculate post metrics including view counts and comment counts
    SELECT p.Id AS PostId,
           SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
           SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
           SUM(COALESCE(a.AnswerCount, 0)) AS TotalAnswers
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2   -- Answers
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    GROUP BY p.Id
)
SELECT 
    ph.PostId,
    COUNT(DISTINCT CASE WHEN ph.Level = 1 THEN ph.AcceptedAnswerId END) AS AcceptedAnswerCount,
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    pm.TotalViews,
    pm.TotalComments,
    pm.TotalAnswers
FROM RecursivePostHierarchy ph
JOIN UserReputationSummary us ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ph.PostId)
JOIN PostMetrics pm ON pm.PostId = ph.PostId
WHERE us.Reputation > 1000  -- Filtering users with reputation greater than 1000
GROUP BY ph.PostId, us.UserId, us.Reputation, us.BadgeCount, us.GoldBadges, us.SilverBadges, us.BronzeBadges, pm.TotalViews, pm.TotalComments, pm.TotalAnswers
HAVING COUNT(DISTINCT ph.AcceptedAnswerId) > 0  -- Include only posts which have accepted answers
ORDER BY us.Reputation DESC, pm.TotalViews DESC;
