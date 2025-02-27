-- Performance Benchmarking Query

-- This query retrieves average score and view count for each post type
-- along with the total number of posts for each type.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AvgScore,
    AVG(p.ViewCount) AS AvgViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- This query retrieves the number of users and their average reputation 
-- created in each year, so we can measure user growth over time

SELECT 
    EXTRACT(YEAR FROM CreationDate) AS CreationYear,
    COUNT(u.Id) AS TotalUsers,
    AVG(u.Reputation) AS AvgReputation
FROM 
    Users u
GROUP BY 
    CreationYear
ORDER BY 
    CreationYear;

-- This query analyzes badge distribution among users by badge class

SELECT 
    b.Class,
    COUNT(b.Id) AS TotalBadges,
    AVG(u.Reputation) AS AvgUserReputation
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.Class
ORDER BY 
    b.Class;

-- This query examines the number of votes per post type

SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS TotalVotes,
    AVG(v.BountyAmount) AS AvgBountyAmount
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
JOIN 
    Posts p ON v.PostId = p.Id
GROUP BY 
    vt.Name
ORDER BY 
    TotalVotes DESC;

-- This query provides insights on comments per post and their average scores

SELECT 
    p.Title,
    COUNT(c.Id) AS TotalComments,
    AVG(c.Score) AS AvgCommentScore
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title
ORDER BY 
    TotalComments DESC
LIMIT 10; -- Get top 10 posts with most comments
