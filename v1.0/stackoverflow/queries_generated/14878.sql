-- Performance benchmarking query to analyze the distribution of posts by type and their respective scores
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS NumberOfPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    MAX(p.CreationDate) AS MostRecentPostDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    NumberOfPosts DESC;

-- Additional benchmark query to gather user engagement metrics
SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS NumberOfPosts,
    SUM(v.BountyAmount) AS TotalBountyAmount,
    SUM(v.VoteTypeId = 2) AS TotalUpVotes,
    SUM(v.VoteTypeId = 3) AS TotalDownVotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 0
ORDER BY 
    TotalUpVotes DESC;

-- Benchmark query to fetch badge distribution among users
SELECT 
    b.Name AS BadgeName,
    COUNT(b.UserId) AS NumberOfHolders,
    MAX(b.Date) AS MostRecentAwardDate
FROM 
    Badges b
GROUP BY 
    b.Name
ORDER BY 
    NumberOfHolders DESC;

-- Performance query to check the slowest performing post types based on average score and view count
SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
HAVING 
    AVG(p.Score) < 0
ORDER BY 
    AverageScore ASC, AverageViews ASC;
