-- Performance benchmarking SQL query for the StackOverflow schema

-- 1. Count the total number of posts by type
SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- 2. Average score of posts for each post type
SELECT 
    pt.Name AS PostType, 
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;

-- 3. Number of posts created per month
SELECT 
    DATE_TRUNC('month', p.CreationDate) AS Month, 
    COUNT(p.Id) AS PostsCount
FROM 
    Posts p
GROUP BY 
    Month
ORDER BY 
    Month;

-- 4. Total votes received by post type
SELECT 
    vt.Name AS VoteType, 
    COUNT(v.Id) AS TotalVotes
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

-- 5. Number of users and average reputation
SELECT 
    COUNT(DISTINCT u.Id) AS TotalUsers, 
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u;

-- 6. Total badges awarded by class
SELECT 
    b.Class AS BadgeClass, 
    COUNT(b.Id) AS TotalBadges
FROM 
    Badges b
GROUP BY 
    b.Class
ORDER BY 
    BadgeClass;
