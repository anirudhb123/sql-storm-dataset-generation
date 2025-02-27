-- Performance Benchmarking Query

-- This query will retrieve the number of posts, average score, and total view count,
-- grouped by Post Type. It will also calculate the average reputation of users who created
-- these posts, to assess user engagement.

WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViewCount,
        AVG(u.Reputation) AS AverageUserReputation
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year' -- consider posts from the last year
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    PostCount,
    AverageScore,
    TotalViewCount,
    AverageUserReputation
FROM 
    PostStats
ORDER BY 
    PostCount DESC;  -- Adjust the order by column as needed for benchmark analysis
