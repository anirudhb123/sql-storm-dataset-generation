-- Performance Benchmarking Query

-- This query retrieves the total number of posts, along with the average score and view count, grouped by post type.
-- It also includes the maximum and minimum scores for performance analysis.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    MAX(p.Score) AS MaxScore,
    MIN(p.Score) AS MinScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- This query benchmarks user activity by calculating the total reputation and average creation date of users
-- who have authored posts, grouped by their reputation level.

SELECT 
    u.Reputation AS UserReputation,
    COUNT(DISTINCT p.Id) AS TotalPostsByUser,
    AVG(u.CreationDate) AS AverageUserCreationDate
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Reputation
ORDER BY 
    TotalPostsByUser DESC;

-- This query measures comment activity by counting comments per post and returns the average number of comments 
-- alongside the total post count for benchmarking purposes.

SELECT 
    p.Title,
    COUNT(c.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Posts) AS TotalPostCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title
ORDER BY 
    CommentCount DESC
LIMIT 10; -- Limit to the top 10 posts with the most comments

-- This query retrieves the total number of votes per post type, summarizing engagement metrics for analysis.

SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VotingEngagement
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    TotalVotes DESC;
