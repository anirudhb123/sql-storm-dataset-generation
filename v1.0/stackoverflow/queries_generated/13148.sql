-- Performance Benchmarking SQL Query

-- 1. Fetch the number of posts and their associated user details 
-- 2. Join with Votes to count total votes for each post
-- 3. Group by Post and User information for aggregate analysis

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2020-01-01' -- Filter posts created from 2020 onwards
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalVotes DESC, p.CreationDate DESC; -- Order by total votes and creation date
