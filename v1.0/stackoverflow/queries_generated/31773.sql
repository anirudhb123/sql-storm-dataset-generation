WITH RecursivePostCTE AS (
    SELECT 
        Id, 
        Title, 
        ParentId, 
        1 AS Layer
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Starting with questions

    UNION ALL
    
    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        Layer + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON r.Id = p.ParentId
    WHERE 
        p.PostTypeId = 2  -- Only considering answers
),
RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(p.Score, 0) AS Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
)
SELECT 
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 'Closed' END), 'Open') AS PostStatus,
    STRING_AGG(DISTINCT tg.TagName, ', ') AS Tags
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.Id = u.Id 
LEFT JOIN 
    PostHistory ph ON rp.Id = ph.PostId 
LEFT JOIN 
    (SELECT 
         Id, 
         UNNEST(STRING_TO_ARRAY(Tags, '>,<')) AS TagName
     FROM 
         Posts) tg ON rp.Id = tg.Id
WHERE 
    rp.RowNum = 1
GROUP BY 
    u.DisplayName,
    u.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount
ORDER BY 
    rp.Score DESC NULLS LAST,
    rp.CreationDate DESC
LIMIT 10;
