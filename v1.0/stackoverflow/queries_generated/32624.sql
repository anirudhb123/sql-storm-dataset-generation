WITH RecursiveTagHierarchy AS (
    SELECT 
        t.Id AS TagId, 
        t.TagName, 
        t.Count, 
        t.ExcerptPostId,
        t.WikiPostId,
        CAST(t.TagName AS varchar(max)) AS FullTagPath
    FROM 
        Tags t
    WHERE 
        t.IsModeratorOnly = 0

    UNION ALL

    SELECT 
        p.Id AS TagId, 
        pt.TagName, 
        pt.Count, 
        pt.ExcerptPostId,
        pt.WikiPostId,
        CAST(CONCAT(r.FullTagPath, ' > ', pt.TagName) AS varchar(max)) AS FullTagPath
    FROM 
        Posts p
    JOIN 
        Tags pt ON pt.ExcerptPostId = p.Id
    JOIN 
        RecursiveTagHierarchy r ON r.TagId = pt.Id
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(p.Score) AS TotalScore,
    AVG(
        CASE 
            WHEN p.ViewCount IS NOT NULL AND p.ViewCount > 0 THEN CAST(p.Score AS float) / p.ViewCount
            ELSE 0 
        END
    ) AS AverageScorePerView,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
    MAX(ph.CreationDate) AS LastPostEditDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId 
LEFT JOIN 
    RecursiveTagHierarchy th ON th.TagId = pl.RelatedPostId
LEFT JOIN 
    Tags t ON th.TagId = t.Id
WHERE 
    u.Reputation > 1000
    AND (u.LastAccessDate IS NULL OR u.LastAccessDate > NOW() - INTERVAL '1 year')
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    TotalScore DESC
LIMIT 50;

In this query:
- A recursive CTE (`RecursiveTagHierarchy`) is created to explore the tags hierarchy, assuming there's a functional relationship based on the `ExcerptPostId` and other details.
- The main query retrieves user information along with the post statistics, including total post count, score, average score per view, associated tags, and the last edit date of the post.
- Various joins are employed to link users, posts, history, and tags.
- NULL logic and filtering are present to manage users with specific criteria, ensuring a proper evaluation of active contributors.
- Finally, results are ordered by total score and limited to the top fifty contributors.
