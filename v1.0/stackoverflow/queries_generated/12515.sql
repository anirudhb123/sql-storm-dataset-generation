-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVotes, -- assuming VoteTypeId = 2 is Upvote
    SUM(v.VoteTypeId = 3) AS DownVotes, -- assuming VoteTypeId = 3 is Downvote
    COUNT(DISTINCT ph.Id) AS EditCount,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    Posts p
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 YEAR' -- filter for posts created in the last year
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC;
