-- Performance benchmarking SQL query to analyze post statistics 
-- and user engagement metrics from the Stack Overflow schema.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    p.CreationDate AS PostCreationDate,
    COUNT(c.Id) AS TotalComments,
    U.DisplayName AS UserDisplayName,
    U.Reputation AS UserReputation,
    U.CreationDate AS UserCreationDate,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
    AVG(v.VoteTypeId) AS AverageVoteType, 
    COUNT(DISTINCT ph.Id) AS PostHistoryCount
FROM 
    Posts p 
LEFT JOIN 
    Users U ON p.OwnerUserId = U.Id 
LEFT JOIN 
    Comments c ON p.Id = c.PostId 
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= '2020-01-01' -- Filter for posts created after Jan 1, 2020
GROUP BY 
    p.Id, U.DisplayName, U.Reputation
ORDER BY 
    p.ViewCount DESC; -- Order by view count to prioritize popular posts
