-- Performance Benchmarking SQL Query

-- Calculate the total number of posts, average score, and average view count by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Measure the total number of votes by vote type
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

-- Count the number of users and calculate the average reputation
SELECT 
    COUNT(u.Id) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u;

-- Check the distribution of badges by class
SELECT 
    b.Class AS BadgeClass,
    COUNT(b.Id) AS TotalBadges
FROM 
    Badges b
GROUP BY 
    b.Class
ORDER BY 
    BadgeClass;

-- Measure the average number of comments per post
SELECT 
    AVG(CommentCount) AS AverageCommentsPerPost
FROM 
    Posts;

-- Check the total number of posts and comments created over time
SELECT 
    DATE_TRUNC('month', CreationDate) AS Month,
    COUNT(p.Id) AS TotalPosts,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    Month
ORDER BY 
    Month;
