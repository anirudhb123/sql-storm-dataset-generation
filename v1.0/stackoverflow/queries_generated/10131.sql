-- Performance Benchmarking SQL Query

-- Index creation for benchmarking efficiency
CREATE INDEX idx_post_owner ON Posts (OwnerUserId);
CREATE INDEX idx_user_reputation ON Users (Reputation);

-- Measuring the number of posts by user along with their reputation
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS NumberOfPosts
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    NumberOfPosts DESC
LIMIT 100;

-- Measuring the most commented posts along with the count of comments
SELECT 
    p.Id AS PostId,
    p.Title,
    p.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, p.Title, p.OwnerDisplayName
ORDER BY 
    CommentCount DESC
LIMIT 100;

-- Evaluating average votes received for posts by type
SELECT 
    pt.Name AS PostType,
    AVG(vt.Id) AS AverageVotes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Votes v ON p.Id = v.PostId
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    pt.Name;

-- Checking performance of posts closure reason types
SELECT 
    crt.Name AS CloseReason,
    COUNT(ph.Id) AS NumberOfClosures
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
JOIN 
    CloseReasonTypes crt ON ph.Comment::int = crt.Id -- Assuming Comment contains the CloseReasonId
WHERE 
    pht.Id = 10 -- Only interested in "Post Closed" history
GROUP BY 
    crt.Name
ORDER BY 
    NumberOfClosures DESC;

-- Benchmarking response times on fetching user statistics
EXPLAIN ANALYZE 
SELECT 
    u.DisplayName,
    SUM(v.BountyAmount) AS TotalBounty
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalBounty DESC
LIMIT 50;

