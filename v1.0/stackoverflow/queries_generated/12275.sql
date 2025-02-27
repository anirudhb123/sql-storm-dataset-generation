-- Performance benchmarking query to retrieve post statistics,
-- including user reputation and votes.
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.Reputation AS OwnerReputation,
    v.VoteCount,
    p.CreationDate,
    p.LastActivityDate,
    p.ClosedDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS VoteCount 
     FROM 
         Votes 
     GROUP BY 
         PostId) v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- filter for posts created in the year 2023
ORDER BY 
    p.LastActivityDate DESC
LIMIT 100; -- limit results to top 100 posts for performance analysis
