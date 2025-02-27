
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 8 THEN v.BountyAmount ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
),

PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(c.Text SEPARATOR '; ') AS CommentTexts
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),

PostHistories AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.PostRank,
    pc.CommentCount,
    pc.CommentTexts,
    ph.LastClosedDate,
    rp.TotalBounty
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId
WHERE 
    rp.PostRank <= 5
    AND (ph.LastClosedDate IS NULL OR ph.LastClosedDate < DATE_SUB('2024-10-01', INTERVAL 30 DAY))
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
