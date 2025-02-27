WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        pt.Name AS PostType,
        1 AS Level
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.ParentId IS NULL  -- Start with top-level posts (no parent)

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        pt.Name AS PostType,
        ph.Level + 1
    FROM Posts p
    JOIN PostHierarchy ph ON p.ParentId = ph.PostId
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,  -- Upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,  -- Downvotes
        COALESCE(SUM(v.VoteTypeId = 10), 0) AS DeletionVotes,  -- Deletions
        COUNT(DISTINCT c.Id) AS CommentCount,  -- Count of comments
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
),

PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM PostHistory ph
    GROUP BY ph.PostId
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

SELECT
    p.Id AS PostId,
    p.Title,
    ps.UpVotes,
    ps.DownVotes,
    ps.DeletionVotes,
    ps.CommentCount,
    ph.Level AS HierarchyLevel,
    ph.PostType,
    COALESCE(phc.HistoryCount, 0) AS EditHistoryCount,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    DATEDIFF(CURRENT_TIMESTAMP, ps.LastActivityDate) AS DaysSinceLastActivity,
    CASE 
        WHEN ps.CommentCount > 5 THEN 'Active Discussion'
        WHEN ps.LastActivityDate < CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 'Stale'
        ELSE 'Moderate Activity'
    END AS ActivityStatus
FROM Posts p
JOIN PostStats ps ON p.Id = ps.PostId
JOIN PostHierarchy ph ON p.Id = ph.PostId
LEFT JOIN PostHistoryCounts phc ON p.Id = phc.PostId
LEFT JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE ps.UpVotes > 0
  AND DATEDIFF(CURRENT_TIMESTAMP, ps.LastActivityDate) < 60
ORDER BY ps.UpVotes DESC, ps.DownVotes ASC, ph.Level ASC;
