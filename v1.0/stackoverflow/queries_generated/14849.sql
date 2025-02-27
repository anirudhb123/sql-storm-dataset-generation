-- Performance Benchmarking Query

-- This query retrieves the count of posts, average views, and average score per post type
-- It helps analyze the performance of different post types by aggregating relevant fields

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViews,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Performance benchmarking of user activity

-- Query to retrieve the total number of posts and average reputation for users
-- This can help in identifying active users based on their post contribution and reputation

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
    TotalPosts DESC;

-- Benchmarking closed posts and reasons for closure

-- This query aggregates the count of closed posts by close reason type 
-- and helps in understanding trends in post closures

SELECT 
    cr.Name AS CloseReason,
    COUNT(ph.PostId) AS TotalClosedPosts
FROM 
    PostHistory ph
JOIN 
    CloseReasonTypes cr ON ph.Comment::int = cr.Id  -- Assuming Comment field contains the CloseReasonId for closure events
WHERE 
    ph.PostHistoryTypeId IN (10, 11) -- Post Closed, Post Reopened 
GROUP BY 
    cr.Name
ORDER BY 
    TotalClosedPosts DESC;

-- Analyzing badge achievements per user

-- This query retrieves the number of badges earned by users and their average reputation
-- It helps in evaluating user's contributions and recognitions in the community

SELECT 
    u.DisplayName,
    COUNT(b.Id) AS TotalBadges,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalBadges DESC;

-- Evaluating user engagement through upvotes and downvotes

-- This query aggregates the total upvotes and downvotes by users for performance insights on user contributions

SELECT 
    u.DisplayName,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalUpVotes DESC;
