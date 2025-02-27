-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the number of posts, average score, and view count per post type.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- This query retrieves the total number of comments and average score per user.
SELECT 
    u.DisplayName AS UserName,
    COUNT(c.Id) AS CommentCount,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Users u
LEFT JOIN 
    Comments c ON u.Id = c.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    CommentCount DESC;

-- This query retrieves the number of votes received by each post along with the post title.
SELECT 
    p.Title,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Title
ORDER BY 
    VoteCount DESC;

-- This query retrieves the average number of badges earned by users by their reputation level.
SELECT 
    CASE 
        WHEN u.Reputation < 100 THEN 'Novice'
        WHEN u.Reputation < 1000 THEN 'Intermediate'
        WHEN u.Reputation < 10000 THEN 'Expert'
        ELSE 'Master'
    END AS ReputationLevel,
    AVG(badgeCount) AS AverageBadges
FROM 
    (SELECT UserId, COUNT(*) AS badgeCount 
     FROM Badges 
     GROUP BY UserId) AS userBadges
JOIN 
    Users u ON userBadges.UserId = u.Id
GROUP BY 
    ReputationLevel
ORDER BY 
    ReputationLevel;

-- This query retrieves the most active users based on posts created and their total view count.
SELECT 
    u.DisplayName AS UserName,
    COUNT(p.Id) AS PostCount,
    SUM(p.ViewCount) AS TotalViewCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalViewCount DESC, PostCount DESC;
