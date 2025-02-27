-- Performance benchmarking SQL query for Stack Overflow schema

-- Fetching the count of posts with the average score grouped by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    MAX(p.ViewCount) AS MaxViewCount,
    MIN(p.ViewCount) AS MinViewCount,
    COUNT(DISTINCT p.OwnerUserId) AS AuthorCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
  
-- Benchmarking the number of votes by post type
SELECT 
    pt.Name AS PostType,
    COUNT(v.Id) AS VoteCount,
    COUNT(DISTINCT v.UserId) AS UniqueVoters
FROM 
    Votes v
JOIN 
    Posts p ON v.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    VoteCount DESC;

-- Analyzing user activity by their reputation and number of posts created
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(p.Id) AS PostsCreated,
    SUM(COALESCE(vs.VoteCount, 0)) AS TotalVotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN (
    SELECT 
        PostId, COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
) vs ON p.Id = vs.PostId
GROUP BY 
    u.Id
ORDER BY 
    Reputation DESC, PostsCreated DESC;

-- Evaluating badge acquisition by users
SELECT 
    u.DisplayName AS UserName,
    COUNT(b.Id) AS BadgeCount,
    MAX(b.Class) AS HighestBadgeClass
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id
ORDER BY 
    BadgeCount DESC, HighestBadgeClass ASC;
