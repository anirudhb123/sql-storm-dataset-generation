WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
        AND p.Score > 0
),

RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditDate,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -2, GETDATE())
    GROUP BY 
        p.Id
),

TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        ra.CommentCount,
        ra.LastEditDate,
        ra.CloseCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentActivity ra ON rp.PostId = ra.PostId
    WHERE 
        rp.Rank <= 10
)

SELECT 
    p.Title,
    p.ViewCount,
    COALESCE(p.Score, 0) AS Score,
    p.OwnerDisplayName,
    p.CommentCount,
    p.LastEditDate,
    CASE 
        WHEN p.CloseCount > 0 THEN 'Closed'
        ELSE 'Active' 
    END AS PostStatus,
    STRING_AGG(DISTINCT SUBSTRING(t.TagName, 1, 20), ', ') AS Tags
FROM 
    TopRankedPosts p
LEFT JOIN 
    STRING_SPLIT(p.Tags, ',') t ON p.Tags IS NOT NULL
GROUP BY 
    p.PostId, p.Title, p.ViewCount, p.Score, p.OwnerDisplayName, p.CommentCount, p.LastEditDate, p.CloseCount
ORDER BY 
    p.Score DESC, p.ViewCount DESC;

This SQL query includes:
- **Common Table Expressions (CTEs)** for processing ranked posts and recent activity.
- **Window functions** (ROW_NUMBER) for ranking posts by score.
- **LEFT JOINs** to gather related information from Users and Comments.
- **COALESCE** to handle NULLs in the score.
- **String manipulation** and aggregation to handle tags.
- **Complex predicates** and conditional logic in the SELECT and WHERE clauses.
