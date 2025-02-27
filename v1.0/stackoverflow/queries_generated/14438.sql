-- Performance Benchmarking Query

-- This query retrieves the most active users, their total post counts, and average scores to analyze performance.
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC, AverageScore DESC
LIMIT 
    10;

-- This query retrieves the total number of posts and average score for different post types to analyze performance.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- This query retrieves the most voted posts to analyze high engagement posts.
SELECT 
    p.Title,
    p.ViewCount,
    COUNT(v.Id) AS TotalVotes,
    AVG(v.CreationDate) AS AverageVoteDate
FROM 
    Posts p
JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, p.Title, p.ViewCount
ORDER BY 
    TotalVotes DESC
LIMIT 
    10;

-- This query retrieves the most common close reasons to analyze post closures.
SELECT 
    chr.Name AS CloseReason,
    COUNT(ph.Id) AS TotalClosures
FROM 
    PostHistory ph
JOIN 
    CloseReasonTypes chr ON ph.Comment::int = chr.Id
WHERE 
    ph.PostHistoryTypeId IN (10, 11)  -- Considering post close and reopen events
GROUP BY 
    chr.Name
ORDER BY 
    TotalClosures DESC;

-- This query retrieves the total number of badges earned and average reputation for users to analyze user engagement.
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(b.Id) AS TotalBadges,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalBadges DESC;
