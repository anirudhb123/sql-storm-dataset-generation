WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year') 
        AND p.Score > 0
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 56 THEN ph.CreationDate END) AS LastBumpDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
PostsWithEdits AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        ph.EditCount,
        ph.LastEditDate,
        ph.ClosureCount,
        ph.LastBumpDate,
        CASE 
            WHEN ph.EditCount >= 5 THEN 'Highly Edited'
            WHEN ph.EditCount BETWEEN 1 AND 4 THEN 'Moderately Edited'
            ELSE 'Not Edited'
        END AS EditCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryAggregates ph ON rp.PostId = ph.PostId
)
SELECT 
    pwe.PostId,
    pwe.Title,
    pwe.CreationDate,
    pwe.Score,
    pwe.ViewCount,
    pwe.Rank,
    (pwe.Upvotes - pwe.Downvotes) AS NetScore,
    pwe.EditCategory,
    CASE 
        WHEN pwe.ClosureCount IS NULL THEN 'Open'
        ELSE 'Closed'
    END AS PostStatus,
    pwe.LastEditDate
FROM 
    PostsWithEdits pwe
WHERE 
    pwe.Rank <= 10
ORDER BY 
    NetScore DESC, pwe.LastEditDate DESC
LIMIT 20;
  
-- Additional section to demonstrate an outer join with NULL logic
SELECT 
    t.TagName,
    COALESCE(p.Title, 'No associated posts') AS PostTitle,
    COUNT(DISTINCT pt.PostId) AS AssociatedPostCount
FROM 
    Tags t
LEFT JOIN 
    Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
LEFT JOIN 
    PostsWithEdits p ON pt.Id = p.PostId
GROUP BY 
    t.TagName, p.Title
HAVING 
    COUNT(DISTINCT pt.PostId) > 0 OR MAX(pt.CreationDate) IS NULL
ORDER BY 
    AssociatedPostCount DESC
LIMIT 10;
