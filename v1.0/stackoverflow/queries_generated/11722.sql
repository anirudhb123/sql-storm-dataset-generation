-- Performance Benchmarking Query for Stack Overflow Schema

-- 1. Retrieve and aggregate data about posts including their types and the total number of votes.
SELECT 
    p.Id AS PostId,
    p.Title,
    pt.Name AS PostType,
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
INNER JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
GROUP BY 
    p.Id, p.Title, pt.Name
ORDER BY 
    TotalVotes DESC
LIMIT 100; -- Limit to the top 100 posts by total votes

-- 2. Analyze user reputation and the badges they have earned.
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(b.Id) AS TotalBadges,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 100; -- Limit to the top 100 users by reputation
