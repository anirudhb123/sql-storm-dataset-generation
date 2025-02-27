-- Performance benchmarking query for StackOverflow schema

-- Analyze the number of posts, their average scores, and the number of comments, grouped by post type
SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS PostCount, 
    AVG(p.Score) AS AvgScore, 
    SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Analyze user reputation and the number of badges held by users
SELECT 
    u.Reputation, 
    COUNT(b.Id) AS BadgeCount
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Reputation
ORDER BY 
    u.Reputation DESC;

-- Retrieve the most active users based on number of posts and comments
SELECT 
    u.DisplayName, 
    COUNT(DISTINCT p.Id) AS PostCount, 
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    (PostCount + CommentCount) DESC 
LIMIT 10;
