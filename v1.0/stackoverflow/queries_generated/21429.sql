WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::INT = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.CloseReasons, 'None') AS CloseReasons,
        rp.Reputation,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top Performer'
            ELSE 'Regular Performer'
        END AS PerformanceCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.CloseCount,
    ps.CloseReasons,
    ps.Reputation,
    ps.PerformanceCategory,
    CASE 
        WHEN ps.CloseCount > 0 THEN 'Engagement with Risk'
        ELSE 'Stable Engagement'
    END AS EngagementRisk,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = ps.PostId) AS CommentCount
FROM 
    PostStatistics ps
WHERE 
    ps.Reputation > 100 -- Only considering users with substantial reputation
ORDER BY 
    ps.Score DESC, ps.CloseCount ASC;

-- Also, consider the unique tag combinations in the posts
SELECT 
    p.Id AS PostId,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    unnest(string_to_array(p.Tags, '>')) AS t ON TRUE
GROUP BY 
    p.Id
HAVING 
    COUNT(DISTINCT t.TagName) > 3; -- Posts with more than 3 unique tags
