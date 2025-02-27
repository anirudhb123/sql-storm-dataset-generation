WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        0 AS Level,
        CAST(p.Title AS VARCHAR(300)) AS Path
    FROM Posts p
    WHERE p.ParentId IS NULL  -- Start with root posts (questions)

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.OwnerUserId,
        p2.PostTypeId,
        r.Level + 1,
        CAST(r.Path || ' -> ' || p2.Title AS VARCHAR(300))
    FROM Posts p2
    INNER JOIN RecursivePostHierarchy r ON p2.ParentId = r.PostId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    COUNT(DISTINCT p.Id) AS PostCount,
    AVG(COALESCE(p.Score, 0)) AS AvgScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    CASE 
        WHEN AVG(p.Score) IS NULL THEN 'No Score'
        WHEN AVG(p.Score) > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS ScoreCategory,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    CASE 
        WHEN COUNT(DISTINCT b.Id) > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Tags t ON position(t.TagName IN p.Tags) > 0  -- Get tags associated with posts
LEFT JOIN Badges b ON u.Id = b.UserId
WHERE u.Reputation > 100  -- Filter users with reputation greater than 100
GROUP BY u.Id, u.DisplayName, u.Reputation
HAVING COUNT(DISTINCT p.Id) > 5  -- Only include users with more than 5 posts
ORDER BY TotalViews DESC, AvgScore DESC;

WITH ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseEvent
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10  -- Closed posts only
),
OpenPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS ReopenReason,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ReopenEvent
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 11  -- Reopened posts only
)

SELECT 
    c.PostId,
    MIN(c.CreationDate) AS CloseDate,
    MIN(o.CreationDate) AS ReopenDate,
    CASE 
        WHEN MIN(o.CreationDate) IS NOT NULL THEN 'Reopened'
        ELSE 'Still Closed'
    END AS Status,
    COUNT(DISTINCT CASE WHEN o.PostId IS NOT NULL THEN o.PostId END) AS ReopenCount,
    COUNT(DISTINCT CASE WHEN c.CloseReason IS NOT NULL THEN c.CloseReason END) AS UniqueCloseReasons
FROM ClosedPosts c
LEFT JOIN OpenPosts o ON c.PostId = o.PostId
GROUP BY c.PostId
HAVING MIN(c.CreationDate) < CURRENT_DATE - INTERVAL '30 days'  -- Filters for posts closed over a month ago
ORDER BY CloseDate DESC;
