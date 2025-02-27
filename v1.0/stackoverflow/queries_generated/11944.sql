SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes,
    COALESCE(SUM(v.VoteTypeId = 1), 0) AS AcceptedAnswers
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
GROUP BY 
    p.Id, p.Title, p.CreationDate
ORDER BY 
    p.CreationDate DESC;
