-- Performance Benchmarking Query

-- This query retrieves the number of posts, average score, and user reputation
-- for posts created in the last year, grouped by PostTypeId. 
-- It helps in assessing the performance of the various post types.

WITH RecentPosts AS (
    SELECT 
        p.PostTypeId,
        p.Score,
        u.Reputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
)
SELECT 
    rp.PostTypeId,
    COUNT(*) AS PostCount,
    AVG(rp.Score) AS AvgScore,
    AVG(rp.Reputation) AS AvgUserReputation
FROM 
    RecentPosts rp
GROUP BY 
    rp.PostTypeId
ORDER BY 
    rp.PostTypeId;
