-- Performance Benchmarking Query
WITH RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        p.Id, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerReputation,
        rp.CommentCount,
        rp.VoteCount,
        RANK() OVER (ORDER BY rp.Score DESC) AS RankScore
    FROM 
        RecentPosts rp
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerReputation,
    tp.CommentCount,
    tp.VoteCount,
    tp.RankScore
FROM 
    TopPosts tp
WHERE 
    tp.RankScore <= 10
ORDER BY 
    tp.RankScore;
