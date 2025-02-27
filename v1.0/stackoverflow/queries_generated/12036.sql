-- Performance Benchmarking Query

-- This query retrieves the total number of posts, average score of posts, 
-- average view count, and count of users who made posts, 
-- providing insight into the overall activity and engagement on the platform.

SELECT 
    COUNT(DISTINCT P.Id) AS TotalPosts,
    AVG(P.Score) AS AveragePostScore,
    AVG(P.ViewCount) AS AverageViewCount,
    COUNT(DISTINCT U.Id) AS TotalUsers
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- considering only posts from the last year

