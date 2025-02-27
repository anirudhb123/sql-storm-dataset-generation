-- Performance benchmarking query for StackOverflow schema

-- This query retrieves the number of posts, average score, and total view count 
-- grouped by post type, and ordered by the highest number of posts.
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

-- Additionally, we can benchmark user activity by fetching the total number of posts 
-- and total upvotes/downvotes per user, ranked by their reputation.
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS UserTotalPosts,
    SUM(v.VoteTypeId = 2) AS TotalUpVotes,  -- Upvotes
    SUM(v.VoteTypeId = 3) AS TotalDownVotes  -- Downvotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    u.Reputation DESC;
