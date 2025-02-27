-- Performance benchmarking query to analyze the distribution of Posts by PostType
SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    MAX(p.CreationDate) AS LastPostDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Performance benchmarking query to analyze user reputation and activity
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS NumberOfPosts,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    AVG(COALESCE(p.Score, 0)) AS AverageScore,
    MAX(u.LastAccessDate) AS LastAccess
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName, u.Reputation
HAVING 
    COUNT(p.Id) > 0
ORDER BY 
    Reputation DESC;

-- Performance benchmarking query to analyze Votes on posts
SELECT 
    vt.Name AS VoteTypeName,
    COUNT(v.Id) AS VoteCount,
    SUM(v.BountyAmount) AS TotalBounty,
    AVG(COALESCE(v.CreationDate, '1970-01-01'::timestamp)) AS AverageVoteDate
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    VoteCount DESC;

-- Performance benchmarking query to analyze Post history types
SELECT 
    pht.Name AS PostHistoryTypeName,
    COUNT(ph.Id) AS HistoryCount,
    AVG(EXTRACT(EPOCH FROM (NOW() - ph.CreationDate))) AS AverageResponseTimeInSeconds
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    HistoryCount DESC;

-- Performance benchmarking query for badge distribution among users
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS TotalBadges,
    AVG(u.Reputation) AS AverageUserReputation,
    COUNT(DISTINCT b.UserId) AS UniqueUsersAwarded
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.Name
ORDER BY 
    TotalBadges DESC;
