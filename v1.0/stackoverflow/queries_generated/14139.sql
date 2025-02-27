-- Performance benchmarking query
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
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
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for the last year
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        VoteCount,
        RANK() OVER (ORDER BY Score DESC) AS ScoreRank,
        RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank
    FROM 
        RankedPosts
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerDisplayName,
    CommentCount,
    VoteCount,
    ScoreRank,
    ViewRank
FROM 
    TopPosts
WHERE 
    ScoreRank <= 10 OR ViewRank <= 10  -- Get top 10 posts by score or views
ORDER BY 
    ScoreRank, ViewRank;
