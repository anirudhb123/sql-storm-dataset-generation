-- Performance benchmarking query to analyze post statistics and user engagement

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  -- Voting status
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes   -- Voting status
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id 
LEFT JOIN 
    Comments c ON p.Id = c.PostId 
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'  -- Filter for the last 30 days
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC;  -- Order by most recent posts
