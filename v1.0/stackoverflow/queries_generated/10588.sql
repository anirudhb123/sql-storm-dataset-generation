-- Performance Benchmarking SQL Query

-- This query retrieves the count of posts, average score, and average view count 
-- grouped by post type and also tracks average user reputation of post owners.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(u.Reputation) AS AverageOwnerReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Track the average time taken (in seconds) for post edits by user
SELECT 
    u.DisplayName,
    AVG(EXTRACT(EPOCH FROM (ph.CreationDate - p.CreationDate))) AS AverageEditTimeSeconds
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    Users u ON ph.UserId = u.Id
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
GROUP BY 
    u.DisplayName
ORDER BY 
    AverageEditTimeSeconds DESC;

-- Check the number of votes per post along with the average vote score
SELECT 
    p.Title,
    COUNT(v.Id) AS VoteCount,
    AVG(v.VoteTypeId) AS AverageVoteType
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Title
ORDER BY 
    VoteCount DESC;

-- Summary of badges awarded to users with respect to their reputation
SELECT 
    u.DisplayName,
    COUNT(b.Id) AS BadgeCount,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    BadgeCount DESC, AverageReputation DESC;
