WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1)
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        COALESCE(cp.CloseCount, 0) AS TotalCloseVotes,
        CASE WHEN cp.CloseCount > 0 THEN 'Closed' ELSE 'Open' END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    *,
    CASE 
        WHEN TotalComments > 10 THEN 'Highly Commented'
        WHEN TotalComments BETWEEN 5 AND 10 THEN 'Moderately Commented'
        ELSE 'Low Comments'
    END AS CommentCategory
FROM 
    PostMetrics
WHERE 
    Rank <= 3
ORDER BY 
    Score DESC, 
    ViewCount DESC;
