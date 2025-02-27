-- Performance Benchmarking Query for Stack Overflow Schema
SELECT 
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS AuthorDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    p.ViewCount,
    p.Score,
    pt.Name AS PostTypeName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= '2022-01-01' -- filtering to include only posts created in 2022 and later
GROUP BY 
    p.Id, u.DisplayName, pt.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- limiting the number of results
