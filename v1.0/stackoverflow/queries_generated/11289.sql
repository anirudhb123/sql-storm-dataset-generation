-- Performance Benchmarking Query

-- Retrieve the distribution of post types along with average scores, view counts, and creation dates for benchmarking
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    MIN(p.CreationDate) AS EarliestPostDate,
    MAX(p.CreationDate) AS LatestPostDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Retrieve the number of active users and their average reputation
SELECT 
    COUNT(u.Id) AS ActiveUserCount,
    AVG(u.Reputation) AS AverageReputation,
    MIN(u.CreationDate) AS EarliestUserDate,
    MAX(u.CreationDate) AS LatestUserDate
FROM 
    Users u
WHERE 
    u.LastAccessDate >= NOW() - INTERVAL '30 days';

-- Retrieve badge distribution by class for users
SELECT 
    b.Class AS BadgeClass,
    COUNT(b.Id) AS BadgeCount
FROM 
    Badges b
GROUP BY 
    b.Class
ORDER BY 
    BadgeClass;

-- Analyze the number of votes received per post type
SELECT 
    pt.Name AS PostType,
    COUNT(v.Id) AS TotalVotes
FROM 
    Votes v
JOIN 
    Posts p ON v.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalVotes DESC;

-- Retrieve the performance of closed posts and their reasons
SELECT 
    p.Title,
    p.CreationDate,
    ph.CreationDate AS CloseDate,
    crt.Name AS CloseReason
FROM 
    Posts p
JOIN 
    PostHistory ph ON p.Id = ph.PostId
JOIN 
    CloseReasonTypes crt ON ph.Comment::int = crt.Id
WHERE 
    ph.PostHistoryTypeId = 10 -- Closed post history type
ORDER BY 
    CloseDate DESC;
