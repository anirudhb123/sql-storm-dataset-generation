WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.Tags,
        p.OwnerUserId,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.ViewCount,
        a.CreationDate,
        a.Score,
        a.Tags,
        a.OwnerUserId,
        Depth + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    WHERE 
        q.PostTypeId = 1 -- Join to retrieve Answers
)
SELECT 
    u.DisplayName AS OwnerName,
    COUNT(DISTINCT p.PostId) AS TotalPosts,
    SUM(CASE WHEN p.Depth > 0 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN p.Depth = 0 THEN p.ViewCount ELSE 0 END) AS TotalViewsOnQuestions,
    AVG(CASE WHEN p.Depth > 0 THEN p.Score ELSE NULL END) AS AverageScoreOfAnswers,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM 
    RecursivePostCTE p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts ps ON ps.OwnerUserId = u.Id AND ps.PostTypeId IN (1, 2)
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(p.Tags, '<>')::int[])
WHERE 
    u.Reputation >= 1000 -- Only consider users with good reputation
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.PostId) > 5 -- Only include users with more than 5 posts
ORDER BY 
    TotalPosts DESC, AverageScoreOfAnswers DESC;
