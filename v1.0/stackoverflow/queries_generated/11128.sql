-- Performance Benchmarking Query

-- Example Benchmarking Query: Retrieve the count of posts, average score, and total views grouped by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Example Benchmarking Query: Retrieve user reputation distribution with the count of badges
SELECT 
    u.Reputation,
    COUNT(b.Id) AS BadgeCount
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Reputation
ORDER BY 
    u.Reputation DESC;

-- Example Benchmarking Query: Retrieve the number of votes by type and post
SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount,
    COUNT(DISTINCT v.PostId) AS TotalPostsVotedOn
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    VoteCount DESC;
