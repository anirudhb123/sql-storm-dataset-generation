-- Performance Benchmarking Query: Retrieve post information along with user details and vote counts for questions

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 -- Only Questions
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit to 100 results for performance benchmarking
