-- Performance Benchmarking SQL Query

-- This query retrieves the count of posts, the average score of questions, 
-- and the total number of comments within a specific time range, 
-- while also joining multiple related tables to gather comprehensive metrics.

WITH PostMetrics AS (
    SELECT 
        COUNT(p.Id) AS PostCount,
        AVG(CASE WHEN p.PostTypeId = 1 THEN p.Score END) AS AvgQuestionScore,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate BETWEEN '2022-01-01' AND '2022-12-31' -- Specify the time range for benchmarking
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    u.DisplayName, 
    pm.PostCount, 
    pm.AvgQuestionScore, 
    pm.TotalComments
FROM 
    PostMetrics pm
JOIN 
    Users u ON u.Id = p.OwnerUserId
ORDER BY 
    pm.PostCount DESC;
