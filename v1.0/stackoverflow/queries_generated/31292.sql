WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        0 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS FullPath
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.OwnerUserId,
        rp.Level + 1,
        CAST(rp.FullPath + ' -> ' + a.Title AS VARCHAR(MAX))
    FROM 
        Posts a
    INNER JOIN 
        Posts qp ON a.ParentId = qp.Id
    INNER JOIN 
        RecursivePostCTE rp ON qp.Id = rp.Id
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
    SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
    MAX(p.CreationDate) AS LastPostDate,
    MIN(p.CreationDate) AS FirstPostDate,
    ARRAY_AGG(DISTINCT rp.FullPath) AS QuestionPaths
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    RecursivePostCTE rp ON p.AcceptedAnswerId = rp.Id
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(p.Id) > 10
ORDER BY 
    u.Reputation DESC;

-- Performance benchmarking by executing this query with different reputation thresholds
-- and tracking execution time to identify optimizations and performance characteristics.
