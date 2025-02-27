WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE((SELECT SUM(v.VoteTypeId = 2) FROM Votes v WHERE v.PostId = p.Id), 0) AS Upvotes,
        COALESCE((SELECT SUM(v.VoteTypeId = 3) FROM Votes v WHERE v.PostId = p.Id), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Upvotes,
    rp.Downvotes,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    pc.LastCommentDate,
    CASE 
        WHEN rp.RowNum <= 10 THEN 'Top 10 Posts'
        ELSE 'Other Posts'
    END AS PostRank
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.RowNum <= 100
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
