
WITH RankedPosts AS (
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
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.Reputation
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerReputation,
        CommentCount,
        VoteCount,
        @rank := IF(@prev_score = Score, @rank, @rank + 1) AS Rank,
        @prev_score := Score
    FROM 
        RankedPosts, (SELECT @rank := 0, @prev_score := NULL) r
    ORDER BY 
        Score DESC, ViewCount DESC
)

SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    OwnerReputation,
    CommentCount,
    VoteCount,
    Rank
FROM 
    TopPosts
WHERE 
    Rank <= 100;
