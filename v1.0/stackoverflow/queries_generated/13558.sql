-- Performance Benchmarking Query

-- Measure the number of posts, users, and votes in the database
SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes;

-- Get average post views, scores, and answer counts
SELECT 
    AVG(ViewCount) AS AvgViews,
    AVG(Score) AS AvgScore,
    AVG(AnswerCount) AS AvgAnswerCount
FROM 
    Posts;

-- Measure the number of edits per post
SELECT 
    PostId,
    COUNT(*) AS EditCount
FROM 
    PostHistory
WHERE 
    PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
GROUP BY 
    PostId
ORDER BY 
    EditCount DESC
LIMIT 10;

-- Check the distribution of post types
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

-- Identify the most active users based on number of posts and edits
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS PostCount,
    COALESCE(SUM(CASE WHEN ph.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS EditCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON u.Id = ph.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    PostCount DESC, EditCount DESC
LIMIT 10;

-- Find the most common close reasons
SELECT 
    crt.Name AS CloseReason,
    COUNT(ph.PostId) AS CloseCount
FROM 
    PostHistory ph
JOIN 
    CloseReasonTypes crt ON ph.Comment::int = crt.Id -- Assuming Comment stores CloseReasonId on closure
WHERE 
    ph.PostHistoryTypeId IN (10, 11) -- Post Closed, Post Reopened
GROUP BY 
    crt.Name
ORDER BY 
    CloseCount DESC;
