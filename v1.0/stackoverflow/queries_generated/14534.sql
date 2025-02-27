-- Performance Benchmarking SQL Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(distinct c.Id) AS CommentCount,
    COUNT(distinct b.Id) AS BadgeCount,
    SUM(v.VoteTypeId IN (2)) AS UpVoteCount, -- Count of Upvotes
    SUM(v.VoteTypeId IN (3)) AS DownVoteCount -- Count of Downvotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2020-01-01' -- Filter for posts created in 2020 or later
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
