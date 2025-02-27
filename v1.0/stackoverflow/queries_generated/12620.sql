-- Performance benchmarking query for StackOverflow schema

-- This query measures the total number of posts, their average score, and the count of votes across all posts
SELECT 
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AveragePostScore,
    SUM(v.Id IS NOT NULL) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Considering only posts created in 2023
GROUP BY 
    p.OwnerUserId
ORDER BY 
    TotalPosts DESC;

-- Performance benchmarking query to find the top 10 users by reputation with their total question counts

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalQuestions
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Only counting Questions
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- Performance benchmarking query to analyze average votes per post type

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(cv.VoteCount) AS AverageVotes
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount
     FROM Votes
     GROUP BY PostId) cv ON p.Id = cv.PostId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Performance benchmarking query to find the number of edits made to each post type

SELECT 
    p.PostTypeId,
    COUNT(ph.Id) AS TotalEdits
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.PostTypeId
ORDER BY 
    TotalEdits DESC;
