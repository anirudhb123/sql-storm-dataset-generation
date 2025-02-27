-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves a summary of posts along with their associated users, vote counts, and badges
-- It will help in benchmarking the performance of SELECT operations across user and post data

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score AS PostScore,
    p.ViewCount,
    u.Id AS UserId,
    u.DisplayName AS UserName,
    u.Reputation,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
    COALESCE(v.TotalVotes, 0) AS TotalVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
         UserId,
         COUNT(*) AS BadgeCount 
     FROM 
         Badges 
     GROUP BY 
         UserId) b ON u.Id = b.UserId
LEFT JOIN 
    (SELECT 
         PostId,
         SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
         SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
         COUNT(*) AS TotalVotes
     FROM 
         Votes 
     GROUP BY 
         PostId) v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2021-01-01' -- Filtering posts created from 2021 onwards
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limiting results for performance measurement
