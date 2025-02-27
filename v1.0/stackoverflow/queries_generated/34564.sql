WITH RecursiveCommentCounts AS (
    SELECT 
        c.PostId,
        COUNT(*) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS rn
    FROM Comments c
    GROUP BY c.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High'
            WHEN u.Reputation >= 100 THEN 'Medium'
            ELSE 'Low' 
        END AS ReputationLevel
    FROM Users u
),
PostWithHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.CreationDate AS LastModifiedDate,
        MAX(ph.CreationDate) OVER (PARTITION BY p.Id) AS LatestHistory,
        p.ViewCount,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Active'
        END AS PostStatus
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
),
Metrics AS (
    SELECT 
        pwh.PostId,
        pwh.Title,
        pwh.CreationDate,
        COALESCE(rcc.TotalComments, 0) AS TotalComments,
        pwh.ViewCount,
        COUNT(DISTINCT ph.UserId) AS UniqueEditors
    FROM PostWithHistory pwh
    LEFT JOIN RecursiveCommentCounts rcc ON pwh.PostId = rcc.PostId
    LEFT JOIN PostHistory ph ON pwh.PostId = ph.PostId
    WHERE pwh.LastModifiedDate IS NOT NULL
    GROUP BY pwh.PostId, pwh.Title, pwh.CreationDate, pwh.ViewCount
)
SELECT 
    m.PostId,
    m.Title,
    m.CreationDate,
    m.TotalComments,
    m.ViewCount,
    u.UserId,
    u.Reputation,
    u.ReputationLevel,
    m.UniqueEditors,
    CASE 
        WHEN m.TotalComments > 10 THEN 'Popular'
        ELSE 'Less Popular'
    END AS Popularity
FROM Metrics m
JOIN Users u ON m.PostId IN (SELECT PostId FROM Votes v WHERE v.UserId = u.Id) -- Users who have voted on the posts
WHERE m.ViewCount > 100 -- Filtering for posts with significant views
ORDER BY m.ViewCount DESC, m.TotalComments DESC;
