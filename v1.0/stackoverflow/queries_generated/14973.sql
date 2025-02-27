-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the total number of posts, users, and badges, while also analyzing the average score and view count of posts. 
-- Additionally, it includes filtering and ordering to benchmark the efficiency of aggregating data across related tables.

SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges,
    AVG(Score) AS AveragePostScore,
    AVG(ViewCount) AS AveragePostViewCount
FROM 
    Posts
WHERE 
    CreationDate >= '2023-01-01' -- Filter for posts created in 2023
    AND PostTypeId = 1 -- Only count questions
GROUP BY 
    YEAR(CreationDate) -- Grouping by year of creation for future scalability
ORDER BY 
    TotalPosts DESC; -- Order results by total posts
