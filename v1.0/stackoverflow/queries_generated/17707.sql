SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(vote.VoteTypeId = 2) AS UpVoteCount,  -- Up votes
    SUM(vote.VoteTypeId = 3) AS DownVoteCount  -- Down votes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes vote ON p.Id = vote.PostId
WHERE 
    p.PostTypeId = 1  -- Only questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
