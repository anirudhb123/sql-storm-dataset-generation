WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate,
        CAST(1 AS INT) AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate,
        Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON p.ParentId = r.PostId
)

-- Main query to benchmark performance
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(pm.PostId) AS TotalPosts,
    SUM(CASE WHEN pm.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN pm.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(p.ViewCount) AS AvgViewCount,
    MAX(p.Score) AS MaxPostScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags,
    (SELECT COUNT(DISTINCT c.Id) 
        FROM Comments c 
        WHERE c.UserId = u.Id) AS TotalComments,
    (SELECT 
        COUNT(DISTINCT ph.Id) 
        FROM PostHistory ph 
        WHERE ph.UserId = u.Id 
        AND ph.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
    ) AS TotalPostHistoryEntries
FROM 
    Users u
LEFT JOIN 
    Posts pm ON u.Id = pm.OwnerUserId
LEFT JOIN 
    Tags t ON pm.Tags LIKE '%' + t.TagName + '%' 
LEFT JOIN 
    Posts p ON pm.AcceptedAnswerId = p.Id
LEFT JOIN 
    RecursiveCTE r ON pm.Id = r.PostId
WHERE 
    u.Reputation > 100
GROUP BY 
    u.Id, 
    u.DisplayName
ORDER BY 
    TotalPosts DESC, 
    TotalQuestions DESC;
