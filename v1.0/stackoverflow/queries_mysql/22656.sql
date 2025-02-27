
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
        AND p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        MIN(ph.Comment) AS CloseComment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId, ph.UserId, ph.CreationDate
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    COALESCE(cp.CloseComment, 'No closure comments') AS ClosureDescription,
    rp.CreationDate,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.CommentCount > 0
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 50;
