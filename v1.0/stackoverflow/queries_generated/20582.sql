WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL '1 year') 
        AND p.Score IS NOT NULL
), 
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.PostTypeId,
        COALESCE(NULLIF(u.DisplayName, ''), 'Anonymous') AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    WHERE 
        rp.Rank <= 5 
        AND rp.PostTypeId = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.CreationDate, rp.PostTypeId, u.DisplayName
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) as CloseCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostMetrics AS (
    SELECT 
        tq.PostId,
        tq.Title,
        tq.Score,
        tq.CreationDate,
        tq.OwnerDisplayName,
        tq.CommentCount,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.LastCloseDate, 'No closure') AS LastCloseDate
    FROM 
        TopQuestions tq
    LEFT JOIN 
        ClosedPosts cp ON tq.PostId = cp.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.Score,
    pm.CreationDate,
    pm.OwnerDisplayName,
    pm.CommentCount,
    pm.CloseCount,
    pm.LastCloseDate,
    CASE
        WHEN pm.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS Status,
    CASE
        WHEN pm.CloseCount = 0 AND pm.CommentCount > 10 THEN 'High Engagement'
        WHEN pm.CloseCount = 0 AND pm.CommentCount <= 10 THEN 'Low Engagement'
        ELSE 'Has Closure'
    END AS EngagementLevel,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostMetrics pm
LEFT JOIN 
    Posts p ON pm.PostId = p.Id
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, '>') AS t
WHERE 
    pm.Score > 10
GROUP BY 
    pm.PostId, pm.Title, pm.Score, pm.CreationDate, pm.OwnerDisplayName, pm.CommentCount, pm.CloseCount, pm.LastCloseDate
ORDER BY 
    pm.CreationDate DESC;
