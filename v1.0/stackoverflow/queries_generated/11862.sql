-- Performance Benchmarking Query
-- This query retrieves information about Posts with their associated Users and Votes, along with the count of Comments and Badges for each User.
-- It aims to analyze the performance of various joins and aggregations in the schema.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    COUNT(c.Id) AS TotalComments,
    COUNT(b.Id) AS TotalBadges,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= '2023-01-01' -- filter for posts created in 2023
GROUP BY 
    p.Id, u.Id
ORDER BY 
    PostScore DESC, TotalComments DESC
LIMIT 100; -- limit results for performance considerations
