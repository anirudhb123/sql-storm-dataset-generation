WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Start with root posts (top-level questions)
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        h.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy h ON p.ParentId = h.Id
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryAggregates AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastHistoryDate,
        STRING_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END, ', ') AS CloseReasons
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    p.Id AS PostId,
    p.Title,
    ph.HistoryCount,
    ph.LastHistoryDate,
    ph.CloseReasons,
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.PositivePostCount,
    u.AverageReputation,
    rh.Level AS PostLevel
FROM 
    RecursivePostHierarchy rh
JOIN 
    Posts p ON rh.Id = p.Id
JOIN 
    PostHistoryAggregates ph ON p.Id = ph.PostId
LEFT JOIN 
    UserStatistics u ON p.OwnerUserId = u.UserId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Filter for recent posts
ORDER BY 
    u.PostCount DESC, 
    ph.LastHistoryDate DESC;
