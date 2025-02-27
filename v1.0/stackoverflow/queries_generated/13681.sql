-- Performance Benchmarking Query

-- Select count of posts, average score, and total views per PostType
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AvgScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Benchmarking Users based on Reputation and Number of Badges
SELECT 
    u.DisplayName AS User,
    u.Reputation,
    COUNT(b.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id
ORDER BY 
    u.Reputation DESC, TotalBadges DESC;

-- Count of Votes per VoteType
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

-- Average number of comments per post type
SELECT 
    pt.Name AS PostType,
    AVG(COALESCE(c.CommentCount, 0)) AS AvgComments
FROM 
    Posts p
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AvgComments DESC;
