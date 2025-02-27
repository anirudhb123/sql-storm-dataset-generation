-- Performance Benchmarking Query for the StackOverflow Schema

-- This query retrieves the count of posts, users, comments, votes, and badges
-- It will help benchmark the performance by measuring the execution time for complex joins and aggregations.

SELECT 
    (SELECT COUNT(*) FROM Posts) AS Total_Posts,
    (SELECT COUNT(*) FROM Users) AS Total_Users,
    (SELECT COUNT(*) FROM Comments) AS Total_Comments,
    (SELECT COUNT(*) FROM Votes) AS Total_Votes,
    (SELECT COUNT(*) FROM Badges) AS Total_Badges,
    (SELECT COUNT(*) FROM Tags) AS Total_Tags,
    (SELECT COUNT(*) FROM PostHistory) AS Total_PostHistories,
    (SELECT COUNT(*) FROM PostLinks) AS Total_PostLinks
FROM 
    dual; -- Use 'DUAL' as a dummy table for SQL compatibility; omit if using a dialect that doesn't require it.

-- Additionally, you can analyze the execution time for fetching most recent posts with user details

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days' 
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit results to the most recent 100 posts
