
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        VoteCount,
        @rownum := @rownum + 1 AS Rank
    FROM 
        RankedPosts, (SELECT @rownum := 0) r
    ORDER BY 
        Score DESC, ViewCount DESC
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    VoteCount
FROM 
    TopPosts
WHERE 
    Rank <= 10 
ORDER BY 
    Score DESC, ViewCount DESC;
