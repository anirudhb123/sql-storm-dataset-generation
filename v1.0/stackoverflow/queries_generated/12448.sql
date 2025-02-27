-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the number of posts created over time,
-- average score of posts, and average reputation of users who created the posts.

WITH PostMetrics AS (
    SELECT 
        DATE_TRUNC('month', CreationDate) AS Month,
        COUNT(*) AS PostCount,
        AVG(Score) AS AvgPostScore,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate IS NOT NULL
    GROUP BY 
        Month
)

SELECT 
    Month,
    PostCount,
    AvgPostScore,
    AvgUserReputation
FROM 
    PostMetrics
ORDER BY 
    Month;
