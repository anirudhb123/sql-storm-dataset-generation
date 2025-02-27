-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves the number of posts, average score, and total views grouped by post type
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

-- This query checks the number of users, their average reputation, and the total number of badges earned
SELECT 
    COUNT(u.Id) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation,
    SUM(b.Id IS NOT NULL) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId;

-- This query evaluates the average comments per post and average score of those comments
SELECT 
    p.Title AS PostTitle,
    COUNT(c.Id) AS TotalComments,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title
ORDER BY 
    TotalComments DESC;

-- This query checks the usage of different vote types by counting votes on posts
SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN v.CreationDate > NOW() - INTERVAL '1 day' THEN 1 ELSE 0 END) AS VotesLast24Hours
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    TotalVotes DESC;
