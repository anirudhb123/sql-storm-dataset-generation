-- Performance Benchmarking SQL Query

-- This query retrieves the top 10 users by reputation, along with the count of their posts, answers, and the total score from their posts
-- Including filters or conditions to isolate the performance of specific actions (like upvotes) can be added as needed.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(COALESCE(p.Score, 0)) AS TotalScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- Additionally, measure the average time taken for post edits by users in the PostHistory table.
-- This can help in understanding how post edits affect overall user engagement and content quality.

SELECT 
    ph.UserId,
    u.DisplayName,
    AVG(EXTRACT(EPOCH FROM (ph.CreationDate - p.CreationDate))) AS AvgEditTime
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    Users u ON ph.UserId = u.Id
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 24) -- Edits for title, body and suggested edits
GROUP BY 
    ph.UserId, u.DisplayName
ORDER BY 
    AvgEditTime DESC;

-- Finally, benchmarking the most common close reasons for posts
SELECT 
    c.Name AS CloseReason,
    COUNT(ph.Id) AS TotalCloseVotes
FROM 
    PostHistory ph
JOIN 
    CloseReasonTypes c ON ph.Comment::int = c.Id
WHERE 
    ph.PostHistoryTypeId = 10 -- Close action
GROUP BY 
    c.Name
ORDER BY 
    TotalCloseVotes DESC;
