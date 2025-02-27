-- Performance benchmarking query for the Stack Overflow schema

-- Calculate the number of posts, average score, and most recent activity date for each post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    MAX(p.LastActivityDate) AS MostRecentActivity
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Retrieve user statistics: total posts and average reputation for each user
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalPosts DESC, AverageReputation DESC;

-- Benchmark post modifications by counting the number of history entries per post
SELECT 
    p.Id AS PostId,
    COUNT(ph.Id) AS TotalHistoryEntries,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.Id
ORDER BY 
    TotalHistoryEntries DESC;

-- Assess the distribution of vote types across posts
SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    VoteCount DESC;

-- Examine the relationship between posts and comments
SELECT 
    p.Id AS PostId,
    COUNT(c.Id) AS TotalComments,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id
ORDER BY 
    TotalComments DESC;
