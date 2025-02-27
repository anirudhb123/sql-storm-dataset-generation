-- Performance Benchmarking SQL query for StackOverflow schema

-- Query to retrieve the count of various post types along with their average score and view count
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

-- Query to retrieve user statistics including reputation and total votes received
SELECT 
    u.DisplayName,
    u.Reputation,
    SUM(CASE WHEN v.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    COUNT(DISTINCT p.Id) AS TotalPosts
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 0
ORDER BY 
    u.Reputation DESC;

-- Query to analyze badge counts by user
SELECT 
    u.DisplayName,
    COUNT(b.Id) AS BadgeCount,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id
ORDER BY 
    BadgeCount DESC;

-- Query to calculate the total comments per post type and average comment score
SELECT 
    pt.Name AS PostType,
    COUNT(c.Id) AS TotalComments,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Comments c
JOIN 
    Posts p ON c.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalComments DESC;
