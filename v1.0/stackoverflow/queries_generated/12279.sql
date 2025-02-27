-- Performance Benchmarking Query
WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.Score,
        pd.OwnerDisplayName,
        pd.CommentCount,
        RANK() OVER (ORDER BY pd.Score DESC) AS PostRank
    FROM 
        PostDetails pd
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.ViewCount,
    t.Score,
    t.OwnerDisplayName,
    t.CommentCount,
    u.VoteCount
FROM 
    TopPosts t
JOIN 
    UserVoteCounts u ON t.OwnerDisplayName = u.UserId
WHERE 
    t.PostRank <= 10;  -- Limit to top 10 posts by score for benchmarking
