WITH RecursiveTagUsage AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY
        t.Id, t.TagName
    UNION ALL
    SELECT
        tu.TagId,
        tu.TagName,
        tu.PostCount + 1
    FROM
        RecursiveTagUsage tu
    JOIN
        PostLinks pl ON pl.RelatedPostId = tu.TagId
    JOIN
        Posts p ON p.Id = pl.PostId
)

SELECT
    u.Id AS UserId,
    u.DisplayName,
    SUM(COALESCE(b.Class, 0)) AS TotalBadges,
    SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
    SUM(v.BountyAmount) AS TotalBounties,
    STRING_AGG(DISTINCT t.TagName, ', ') AS PopularTags,
    AVG(CASE WHEN p.CreationDate < NOW() - INTERVAL '1 year' THEN p.Score END) AS AverageOldPostScore
FROM
    Users u
LEFT JOIN
    Badges b ON b.UserId = u.Id
LEFT JOIN
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN
    Votes v ON v.UserId = u.Id
LEFT JOIN
    Tags t ON p.Tags LIKE '%' || t.TagName || '%'
WHERE
    u.Reputation >= 100
GROUP BY
    u.Id, u.DisplayName
HAVING
    SUM(COALESCE(b.Class, 0)) > 0 OR COUNT(p.Id) > 5
ORDER BY
    TotalBadges DESC,
    TotalAnswers DESC
LIMIT 10;

WITH RecentActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY
        p.Id, p.Title, p.ViewCount
)

SELECT
    r.PostId,
    r.Title,
    r.ViewCount,
    r.CommentCount,
    u.DisplayName AS OwnerDisplayName
FROM
    RecentActivity r
INNER JOIN
    Users u ON r.OwnerUserId = u.Id
WHERE
    r.rn = 1
ORDER BY
    r.ViewCount DESC;

SELECT
    ph.PostId,
    COUNT(ph.Id) AS EditCount,
    MAX(ph.CreationDate) AS LastEditDate
FROM
    PostHistory ph
JOIN
    Posts p ON p.Id = ph.PostId
WHERE
    ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
GROUP BY
    ph.PostId
HAVING
    COUNT(ph.Id) > 1
ORDER BY
    LastEditDate DESC
LIMIT 10;
