WITH RecursivePostCTE AS (
    SELECT
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        1 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Only Questions

    UNION ALL

    SELECT
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        Level + 1
    FROM
        Posts p
    INNER JOIN Posts a ON p.ParentId = a.Id
    WHERE
        a.PostTypeId = 1 -- Only Questions
)

SELECT
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    AVG(p.Score) AS AverageScore,
    MAX(p.CreationDate) AS MostRecentQuestion,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosedPosts,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS QuestionRank
FROM
    Users u
LEFT JOIN
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN
    Tags t ON p.Tags LIKE '%' || t.TagName || '%'
LEFT JOIN
    PostHistory ph ON p.Id = ph.PostId
WHERE
    u.Reputation > 100
GROUP BY
    u.Id, u.DisplayName
HAVING
    COUNT(DISTINCT p.Id) > 5
ORDER BY
    TotalViews DESC,
    AverageScore DESC;

WITH UserBadgeCount AS (
    SELECT
        UserId,
        COUNT(*) AS BadgeCount
    FROM
        Badges
    GROUP BY
        UserId
)

SELECT
    u.DisplayName,
    ubc.BadgeCount
FROM
    Users u
INNER JOIN
    UserBadgeCount ubc ON u.Id = ubc.UserId
WHERE
    ubc.BadgeCount > 0
ORDER BY
    ubc.BadgeCount DESC;

