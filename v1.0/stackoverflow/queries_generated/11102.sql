-- Performance benchmarking query for StackOverflow schema

-- This query retrieves the total number of posts, users, and comments
-- alongside the average score of the posts and the total count of badges per user.

SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    AVG(Score) AS AveragePostScore,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges
FROM 
    Posts
WHERE 
    CreationDate >= '2023-01-01' -- Filtering posts created in the year 2023
    AND ViewCount > 100;          -- Only consider posts with more than 100 views

-- Optional: You can also check the distribution of post types
SELECT 
    PostTypeId, 
    COUNT(*) AS PostCount
FROM 
    Posts
GROUP BY 
    PostTypeId
ORDER BY 
    PostCount DESC;

-- Optional: Measure execution time for a specific query or overall statistics
-- You can use the following SQL commands in a SQL tool that supports performance analysis:
-- SET STATISTICS TIME ON; 
-- SET STATISTICS IO ON;
