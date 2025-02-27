-- Performance benchmarking query to analyze the number of posts, average score, 
-- and the number of votes per post type over a specified time period.

WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(v.Id IS NOT NULL) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND p.CreationDate < '2023-10-01'  -- Modify this date range as needed
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    PostCount,
    AverageScore,
    TotalVotes
FROM 
    PostMetrics
ORDER BY 
    PostCount DESC;
