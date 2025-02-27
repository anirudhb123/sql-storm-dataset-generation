-- Performance Benchmarking Query

-- This query retrieves the number of posts, average score, and total view count grouped by post type.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- This query calculates the average reputation of users who have posted questions.
SELECT 
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.PostTypeId = 1;  -- PostTypeId = 1 indicates Questions

-- This query returns the total number of votes per post type.
SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS TotalVotes
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    TotalVotes DESC;

-- This query finds the number of badges earned by users that have posted answers.
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS TotalEarned
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.PostTypeId = 2  -- PostTypeId = 2 indicates Answers
GROUP BY 
    b.Name
ORDER BY 
    TotalEarned DESC;
