-- Performance benchmarking query to retrieve statistics about posts along with their associated user and vote count
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT c.Id) AS TotalComments,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    p.Score,
    p.ViewCount,
    p.Tags,
    p.AnswerCount,
    p.FavoriteCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
