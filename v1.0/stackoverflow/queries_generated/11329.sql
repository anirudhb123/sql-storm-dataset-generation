-- Performance benchmarking query for Stack Overflow schema

-- Measure average user reputation for posts with the highest score
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    AVG(u.Reputation) AS AvgReputation,
    COUNT(p.Id) AS PostCount,
    MAX(p.Score) AS MaxScore
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.Score > 0
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    AvgReputation DESC
LIMIT 10;

-- Fetch total number of posts, comments, and votes for performance evaluation
SELECT 
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId;

-- Analyze average time taken to post answers after questions have been created
SELECT 
    p1.Id AS QuestionId,
    p1.Title AS QuestionTitle,
    AVG(EXTRACT(EPOCH FROM (p2.CreationDate - p1.CreationDate)) / 60) AS AvgMinutesToAnswer
FROM 
    Posts p1
JOIN 
    Posts p2 ON p1.Id = p2.ParentId
WHERE 
    p1.PostTypeId = 1  -- Question
    AND p2.PostTypeId = 2  -- Answer
GROUP BY 
    p1.Id, p1.Title
ORDER BY 
    AvgMinutesToAnswer ASC
LIMIT 10;

-- Check for the most common close reason type, useful for evaluating moderation effectiveness
SELECT 
    cht.Name AS CloseReason,
    COUNT(ph.Id) AS TotalClosures
FROM 
    PostHistory ph
JOIN 
    CloseReasonTypes cht ON ph.Comment::int = cht.Id
WHERE 
    ph.PostHistoryTypeId = 10  -- Post Closed
GROUP BY 
    cht.Name
ORDER BY 
    TotalClosures DESC
LIMIT 5;
