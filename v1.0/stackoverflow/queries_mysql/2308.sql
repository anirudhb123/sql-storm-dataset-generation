
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56' - INTERVAL 1 YEAR 
        AND p.PostTypeId IN (1, 2)
), RecentVotes AS (
    SELECT 
        v.PostId, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= '2023-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        v.PostId
), PostsWithComments AS (
    SELECT 
        p.Id AS PostId, 
        COALESCE(cc.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) cc ON p.Id = cc.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rv.Upvotes,
    rv.Downvotes,
    pc.CommentCount,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top Post'
        ELSE 'Other Posts'
    END AS PostRankCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    PostsWithComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
