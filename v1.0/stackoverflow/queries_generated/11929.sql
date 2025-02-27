-- Performance benchmarking query for StackOverflow schema

-- This query retrieves the total number of posts, average view count, and total votes per post type
SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    COALESCE(AVG(p.ViewCount), 0) AS AvgViewCount, 
    SUM(v.VoteTypeId = 2) AS TotalUpVotes, -- UpMod votes
    SUM(v.VoteTypeId = 3) AS TotalDownVotes -- DownMod votes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Performance benchmarking query for user engagement

-- This query fetches the total number of users, average reputation and total badges earned by users
SELECT 
    COUNT(u.Id) AS TotalUsers, 
    COALESCE(AVG(u.Reputation), 0) AS AvgReputation, 
    COUNT(b.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId;
