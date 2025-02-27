SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVoteCount,
    SUM(v.VoteTypeId = 3) AS DownVoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
