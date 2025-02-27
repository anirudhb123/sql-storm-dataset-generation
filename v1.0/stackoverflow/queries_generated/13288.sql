-- Performance Benchmarking Query

-- Retrieve the count of posts, average score, and average view count per post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Retrieve the count of users and their average reputation
SELECT 
    COUNT(u.Id) AS UserCount,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u;

-- Retrieve the count of badges per user and the average badge class
SELECT 
    u.DisplayName,
    COUNT(b.Id) AS BadgeCount,
    AVG(b.Class) AS AverageBadgeClass
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName;

-- Retrieve the total number of votes and average votes per post
SELECT 
    p.Title,
    COUNT(v.Id) AS TotalVotes,
    AVG(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS AverageVoteType
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Title
ORDER BY 
    TotalVotes DESC;

-- Retrieve post history counts grouped by type
SELECT 
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS HistoryCount
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    HistoryCount DESC;
