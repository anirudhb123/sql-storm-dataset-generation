-- Performance Benchmarking Query

-- This query retrieves aggregated statistics on posts along with user details and the top badge earned by users.
-- It measures the following metrics:
-- 1. Total number of posts
-- 2. Total view count
-- 3. Total score of posts
-- 4. Average reputation of users who own those posts
-- 5. Most recent badge earned by post owners

SELECT 
    COUNT(P.Id) AS TotalPosts,
    SUM(P.ViewCount) AS TotalViewCount,
    SUM(P.Score) AS TotalScore,
    AVG(U.Reputation) AS AverageUserReputation,
    (SELECT 
        B.Name 
     FROM 
        Badges B 
     WHERE 
        B.UserId = U.Id 
     ORDER BY 
        B.Date DESC 
     LIMIT 1) AS RecentBadge
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
GROUP BY 
    U.Id
ORDER BY 
    TotalScore DESC
LIMIT 10; -- Limit to top 10 users by total score of posts
