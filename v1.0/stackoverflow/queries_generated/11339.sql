-- Performance benchmarking query to analyze post activity and user engagement in the StackOverflow schema

WITH PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName, p.Score
)

SELECT 
    PostId,
    Title,
    CommentCount,
    VoteCount,
    ViewCount,
    CreationDate,
    OwnerDisplayName,
    Score,
    (CommentCount + VoteCount) AS TotalEngagement  -- Calculate total engagement
FROM 
    PostEngagement
ORDER BY 
    TotalEngagement DESC
LIMIT 100;  -- Limit results to the top 100 posts by engagement
