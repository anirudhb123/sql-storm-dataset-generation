WITH RecursivePostCTE AS (
    SELECT
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        1 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Start from questions
    UNION ALL
    SELECT
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        Level + 1
    FROM
        Posts p
    INNER JOIN RecursivePostCTE r ON p.ParentId = r.Id
)
SELECT
    u.DisplayName,
    COUNT(DISTINCT r.Id) AS QuestionsCount,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    AVG(p.Score) AS AverageScore,
    MAX(p.CreationDate) AS LastQuestionDate,
    STRING_AGG(DISTINCT STRING_AGG(t.TagName, ', ') FILTER (WHERE t.Id IS NOT NULL), '; ') AS Tags,
    CASE 
        WHEN SUM(COALESCE(p.Score, 0)) > 100 THEN 'High Engagement'
        WHEN SUM(COALESCE(p.Score, 0)) BETWEEN 50 AND 100 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM
    Users u
INNER JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Tags t ON t.Id IN (SELECT unnest(string_to_array(p.Tags, ', '))::int)
INNER JOIN RecursivePostCTE r ON r.OwnerUserId = u.Id
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT r.Id) > 5  -- Only users with more than 5 questions
ORDER BY 
    TotalViews DESC, AverageScore DESC
LIMIT 10;
