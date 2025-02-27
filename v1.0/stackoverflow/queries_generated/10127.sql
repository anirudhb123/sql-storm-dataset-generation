-- Performance Benchmarking SQL Query

-- This query retrieves a summary of posts, along with their corresponding user data and vote counts
-- It aggregates data to measure the performance of retrieving posts and their associated information.

WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
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
        VoteCount,
        RANK() OVER (ORDER BY Score DESC) AS Rank
    FROM 
        PostSummary
)

SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerDisplayName,
    VoteCount
FROM 
    TopPosts
WHERE 
    Rank <= 10 -- Change this value to retrieve more or fewer top posts
ORDER BY 
    Rank;
