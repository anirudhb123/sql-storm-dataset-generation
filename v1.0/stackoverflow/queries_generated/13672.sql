-- Performance Benchmarking Query: Count of Posts by Type and Average Score
SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Performance Benchmarking Query: Top 10 Users by Reputation and Total Post Count
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- Performance Benchmarking Query: Average Views per Post Type
SELECT 
    pt.Name AS PostTypeName,
    AVG(p.ViewCount) AS AverageViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AverageViews DESC;

-- Performance Benchmarking Query: Average Comment Count per Post Type
SELECT 
    pt.Name AS PostTypeName,
    AVG(p.CommentCount) AS AverageComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AverageComments DESC;

-- Performance Benchmarking Query: Total Votes by Vote Type
SELECT 
    vt.Name AS VoteTypeName,
    COUNT(v.Id) AS TotalVotes
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    TotalVotes DESC;
