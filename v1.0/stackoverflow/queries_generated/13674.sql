SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(COUNT(c.Id), 0) AS CommentCount,
    COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpVotes,
    COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS DownVotes,
    COALESCE(SUM(v.VoteTypeId = 6)::int, 0) AS CloseVotes
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
