WITH RecursivePostCTE AS (
    -- Recursive CTE to retrieve hierarchy of posts (questions and answers)
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Start with questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.PostId
),
AggregateViews AS (
    -- Calculate total views per user who owns the posts
    SELECT 
        u.Id AS UserId,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    -- Averaging post timestamp differences for recently edited posts
    SELECT 
        ph.PostId,
        AVG(EXTRACT(EPOCH FROM (ph.CreationDate - LEAD(ph.CreationDate) OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate))) / 60) AS AvgTimeBetweenEdits
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Edit Title or Edit Body
    GROUP BY 
        ph.PostId
)

SELECT
    p.Id,
    p.Title,
    up.DisplayName AS Owner,
    up.Reputation,
    COALESCE(total.TotalViews, 0) AS OwnerTotalViews,
    COALESCE(r.Level, 0) AS PostLevel,
    COALESCE(s.AvgTimeBetweenEdits, 0) AS AvgEditTime
FROM 
    Posts p
LEFT JOIN 
    Users up ON p.OwnerUserId = up.Id
LEFT JOIN 
    AggregateViews total ON up.Id = total.UserId
LEFT JOIN 
    RecursivePostCTE r ON p.Id = r.PostId
LEFT JOIN 
    PostHistoryStats s ON p.Id = s.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for posts created in the last year
    AND (up.Reputation IS NOT NULL OR r.Level IS NOT NULL) -- Only interested in posts with owners or structured responses
ORDER BY 
    OwnerTotalViews DESC, p.CreationDate DESC
LIMIT 10;

