WITH RecursiveTagHierarchy AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        t.Count,
        CAST(t.TagName AS VARCHAR(1000)) AS TagPath
    FROM
        Tags t
    WHERE
        t.Count > 0
    
    UNION ALL
    
    SELECT
        t.Id AS TagId,
        t.TagName,
        t.Count,
        CONCAT(r.TagPath, ' -> ', t.TagName) AS TagPath
    FROM
        Tags t
    INNER JOIN
        PostLinks pl ON pl.RelatedPostId = t.Id
    INNER JOIN
        RecursiveTagHierarchy r ON r.TagId = pl.PostId
)

SELECT
    u.DisplayName,
    u.Reputation,
    COALESCE(SUM(b.Class), 0) AS TotalBadges,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    STRING_AGG(DISTINCT rt.TagPath, '; ') AS RelatedTags
FROM
    Users u
LEFT JOIN
    Badges b ON u.Id = b.UserId
LEFT JOIN
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN
    PostLinks pl ON pl.PostId = p.Id
LEFT JOIN
    RecursiveTagHierarchy rt ON rt.TagId = pl.RelatedPostId
WHERE
    u.Reputation > 100 AND u.Location IS NOT NULL
GROUP BY
    u.Id
HAVING
    COUNT(DISTINCT p.Id) > 5
ORDER BY
    TotalPosts DESC, u.Reputation DESC

