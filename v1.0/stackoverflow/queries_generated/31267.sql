WITH RecursivePostHierarchy AS (
    -- Get all posts with their parent-child relationships using recursion
    SELECT Id, ParentId, Title, CreationDate, 1 AS Level
    FROM Posts
    WHERE ParentId IS NULL
    
    UNION ALL
    
    SELECT p.Id, p.ParentId, p.Title, p.CreationDate, r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserMetrics AS (
    -- Calculate user metrics including total votes and badges
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
           COUNT(DISTINCT b.Id) AS TotalBadges,
           AVG(b.Class) AS AvgBadgeClass
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostMetrics AS (
    -- Get post-related metrics including answer counts and average scores
    SELECT p.Id AS PostId,
           p.Title,
           p.OwnerUserId,
           COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
           AVG(COALESCE(p.Score, 0)) AS AvgScore,
           COUNT(DISTINCT ph.Id) AS EditCount
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.OwnerUserId IS NOT NULL
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
CombinedMetrics AS (
    -- Combine user and post metrics
    SELECT up.UserId,
           up.DisplayName,
           up.Reputation,
           pm.PostId,
           pm.Title,
           pm.TotalAnswers,
           pm.AvgScore,
           up.TotalUpVotes,
           up.TotalDownVotes,
           up.TotalBadges,
           up.AvgBadgeClass
    FROM UserMetrics up
    JOIN PostMetrics pm ON up.UserId = pm.OwnerUserId
)
-- Final selection of metrics
SELECT cm.UserId,
       cm.DisplayName,
       cm.Reputation,
       cm.PostId,
       cm.Title,
       cm.TotalAnswers,
       cm.AvgScore,
       cm.TotalUpVotes,
       cm.TotalDownVotes,
       cm.TotalBadges,
       cm.AvgBadgeClass,
       RANK() OVER (ORDER BY cm.Reputation DESC) AS ReputationRank,
       CASE WHEN COUNT(*) FILTER (WHERE cm.TotalAnswers > 0) > 0 THEN 'Active' ELSE 'Inactive' END AS UserStatus
FROM CombinedMetrics cm
GROUP BY cm.UserId, cm.DisplayName, cm.Reputation, cm.PostId, cm.Title,
         cm.TotalAnswers, cm.AvgScore, cm.TotalUpVotes, cm.TotalDownVotes,
         cm.TotalBadges, cm.AvgBadgeClass
ORDER BY cm.Reputation DESC, cm.TotalAnswers DESC
LIMIT 100;
