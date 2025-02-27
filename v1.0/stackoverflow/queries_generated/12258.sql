-- Performance Benchmarking Query

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(a.Id) AS AnswerCount,
    SUM(v.VoteTypeId = 2) AS UpVoteCount, -- UpMod votes
    SUM(v.VoteTypeId = 3) AS DownVoteCount -- DownMod votes
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Posts a ON p.Id = a.ParentId -- Join to get related answers
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 -- Filter for Questions only
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100; -- Adjust limit as necessary for benchmarking
