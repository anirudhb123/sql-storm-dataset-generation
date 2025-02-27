-- Performance Benchmarking Query

-- This query retrieves the count of posts, average scores, and user reputation
-- It uses common table expressions (CTEs) and joins across multiple tables
-- to benchmark performance.

WITH PostSummary AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT
    p.PostTypeId,
    ps.PostCount,
    ps.AvgScore,
    ur.AvgReputation
FROM 
    PostSummary ps
JOIN 
    UserReputation ur ON ur.UserId IN (SELECT OwnerUserId FROM Posts WHERE PostTypeId = p.PostTypeId)
ORDER BY 
    ps.PostCount DESC;
