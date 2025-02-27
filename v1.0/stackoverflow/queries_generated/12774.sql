-- Performance Benchmarking SQL Query

-- This query will provide information on the posts with their associated users, votes, and comments
-- It will help analyze the number of interactions on each post and the reputation of the users involved

WITH PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score AS PostScore,
        p.ViewCount,
        u.Reputation AS UserReputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation
)

SELECT 
    PostId,
    Title,
    PostCreationDate,
    PostScore,
    ViewCount,
    UserReputation,
    CommentCount,
    VoteCount
FROM 
    PostInteraction
ORDER BY 
    PostScore DESC, CommentCount DESC
LIMIT 100;  -- Limit the results to the top 100 posts by score
