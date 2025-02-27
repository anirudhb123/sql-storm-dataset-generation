-- Performance Benchmarking Query

-- This query will retrieve a summary of posts, their related users, and associated votes
-- to assess the performance of data retrieval across multiple tables.
-- It will join the Posts, Users, and Votes tables to get a comprehensive overview of post performance.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 -- Only selecting questions
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC;
