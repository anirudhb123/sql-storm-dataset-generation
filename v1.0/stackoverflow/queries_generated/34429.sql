WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(cp.ParentId, 0) AS ParentId,
        0 AS Depth
    FROM 
        Posts p
    LEFT JOIN 
        Posts cp ON p.AcceptedAnswerId = cp.Id
    WHERE 
        p.PostTypeId = 1 -- Select only questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        cp.ParentId,
        Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE cte ON p.ParentId = cte.PostId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreQuestions,
    AVG(DISTINCT CASE WHEN ph.PostHistoryTypeId = 3 THEN p.Score END) AS AvgAcceptedAnswersScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (3, 10) -- Accepted answer or closed
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Tags t ON pl.RelatedPostId = t.Id
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    Reputation DESC;
