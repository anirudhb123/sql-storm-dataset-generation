-- Performance benchmarking query using the Stack Overflow schema

-- This query gets the number of posts and their average score per post type.
SELECT 
    pt.Name AS PostType,
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

-- This query fetches the total number of votes per post along with their type.
SELECT 
    v.VoteTypeId,
    COUNT(v.Id) AS TotalVotes
FROM 
    Votes v
GROUP BY 
    v.VoteTypeId
ORDER BY 
    TotalVotes DESC;

-- This query retrieves the number of users along with their average reputation.
SELECT 
    COUNT(u.Id) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u;

-- This query checks the distribution of badges among users.
SELECT 
    b.Class,
    COUNT(b.Id) AS BadgeCount
FROM 
    Badges b
GROUP BY 
    b.Class
ORDER BY 
    BadgeCount DESC;

-- This query calculates the average comment score per post.
SELECT 
    p.Title,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title
ORDER BY 
    AverageCommentScore DESC
LIMIT 10;
