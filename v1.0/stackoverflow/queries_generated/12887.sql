-- Performance benchmarking query for StackOverflow schema

-- This query retrieves all posts along with the count of their votes, comments, and associated user details
-- to analyze their performance based on engagement metrics.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    COALESCE(v.VoteCount, 0) AS TotalVotes,
    u.Reputation AS UserReputation,
    u.DisplayName AS UserDisplayName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS UserBadgesCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount 
     FROM Votes 
     GROUP BY PostId) v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  -- Filter for posts created in 2023 for benchmarking
ORDER BY 
    p.ViewCount DESC  -- Ordering by view count to analyze popular posts
LIMIT 100;  -- Limiting to top 100 posts for performance analysis
