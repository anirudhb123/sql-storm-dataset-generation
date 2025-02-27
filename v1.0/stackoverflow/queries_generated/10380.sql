-- Performance benchmarking query for StackOverflow schema

-- This query retrieves statistics of posts, users, and related data to assess performance.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN p.PostTypeId = 4 THEN 1 ELSE 0 END) AS TotalTagWikis,
    SUM(CASE WHEN p.PostTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosedPosts,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- This will help to understand the distribution of posts, engagement through views, 
-- and user contributions in the past year, facilitating performance analysis.
