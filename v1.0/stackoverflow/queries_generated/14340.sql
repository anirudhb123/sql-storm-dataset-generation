-- Performance benchmarking for various operations in the Stack Overflow schema

-- 1. Count the number of posts by type
SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS PostCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- 2. Average reputation of users who have posted answers
SELECT 
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.PostTypeId = 2; -- 2 = Answer

-- 3. Most common close reason for posts
SELECT 
    crt.Name AS CloseReason, 
    COUNT(ph.Id) AS CloseReasonCount
FROM 
    PostHistory ph
JOIN 
    CloseReasonTypes crt ON ph.Comment::int = crt.Id -- Assume the JSON decoded value fits
WHERE 
    ph.PostHistoryTypeId IN (10, 11) -- Close and Reopen
GROUP BY 
    crt.Name
ORDER BY 
    CloseReasonCount DESC;

-- 4. Total number of comments and their average length
SELECT 
    COUNT(c.Id) AS TotalComments, 
    AVG(LENGTH(c.Text)) AS AverageCommentLength
FROM 
    Comments c;

-- 5. Total votes and the average score for posts
SELECT 
    COUNT(v.Id) AS TotalVotes, 
    AVG(p.Score) AS AverageScore
FROM 
    Votes v
JOIN 
    Posts p ON v.PostId = p.Id;

-- 6. Users with the most badges
SELECT 
    u.DisplayName, 
    COUNT(b.Id) AS BadgeCount
FROM 
    Users u
JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    BadgeCount DESC
LIMIT 10;

-- 7. Most active users based on posts created
SELECT 
    u.DisplayName, 
    COUNT(p.Id) AS PostCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    PostCount DESC
LIMIT 10;

-- 8. Posts created by date to see trend over time
SELECT 
    DATE(CreationDate) AS PostDate, 
    COUNT(Id) AS PostsCreated
FROM 
    Posts
GROUP BY 
    PostDate
ORDER BY 
    PostDate ASC;

-- 9. Most popular tags with number of associated posts
SELECT 
    t.TagName, 
    t.Count AS PostCount
FROM 
    Tags t
ORDER BY 
    t.Count DESC
LIMIT 10;

-- 10. User activity analysis: Posts and Votes
SELECT 
    u.DisplayName, 
    COUNT(DISTINCT p.Id) AS PostsCount, 
    COUNT(DISTINCT v.Id) AS VotesCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    PostsCount DESC, VotesCount DESC;
