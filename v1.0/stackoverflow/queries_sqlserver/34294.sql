
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 8 THEN v.BountyAmount END) OVER (PARTITION BY p.Id), 0) AS TotalBounty,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
PostHistoryWithComments AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.UserId) AS EditorsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    LEFT JOIN 
        Comments c ON ph.PostId = c.PostId
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.Score,
    rp.TotalBounty,
    ph.CommentsCount,
    ph.EditorsCount,
    ph.LastEditDate,
    CASE 
        WHEN rp.CommentCount > 5 THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    RankedPosts rp
JOIN 
    PostHistoryWithComments ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
