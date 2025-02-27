WITH RecursivePostCTE AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level,
        p.AcceptedAnswerId
    FROM
        Posts p
    WHERE
        p.ParentId IS NULL

    UNION ALL

    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        Level + 1 AS Level,
        p.AcceptedAnswerId
    FROM
        Posts p
    INNER JOIN RecursivePostCTE r ON r.PostId = p.ParentId
)
SELECT
    u.DisplayName AS UserName,
    COUNT(DISTINCT post.PostId) AS TotalPosts,
    SUM(post.ViewCount) AS TotalViews,
    SUM(CASE WHEN post.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
    AVG(post.ViewCount) AS AverageViews,
    STRING_AGG(DISTINCT tag.TagName, ', ') AS Tags,
    MAX(b.Date) AS LastBadgeDate,
    b.Class AS BadgeClass
FROM
    Users u
LEFT JOIN
    Posts post ON u.Id = post.OwnerUserId
LEFT JOIN
    Tags tag ON post.Tags LIKE CONCAT('%', tag.TagName, '%')
LEFT JOIN
    Badges b ON u.Id = b.UserId
WHERE
    u.Reputation > 100 AND
    post.CreationDate >= NOW() - INTERVAL '1 YEAR'
GROUP BY
    u.DisplayName, b.Class
HAVING
    COUNT(DISTINCT post.PostId) > 5
ORDER BY
    TotalViews DESC
LIMIT 10;

-- Adding an outer join to include users with no posts
SELECT
    u.DisplayName AS UserName,
    COALESCE(post_count.TotalPosts, 0) AS TotalPosts,
    COALESCE(post_views.TotalViews, 0) AS TotalViews
FROM
    Users u
LEFT JOIN (
    SELECT
        OwnerUserId,
        COUNT(Id) AS TotalPosts,
        SUM(ViewCount) AS TotalViews
    FROM
        Posts
    GROUP BY
        OwnerUserId
) post_count ON u.Id = post_count.OwnerUserId
LEFT JOIN (
    SELECT
        OwnerUserId,
        SUM(ViewCount) AS TotalViews
    FROM
        Posts
    GROUP BY
        OwnerUserId
) post_views ON u.Id = post_views.OwnerUserId
WHERE
    u.Reputation < 100
ORDER BY
    TotalPosts DESC, TotalViews DESC;

-- Correlated subquery to find posts with most comments and their last edit date
SELECT
    p.Id AS PostId,
    p.Title,
    p.CommentCount,
    (SELECT MAX(LastEditDate) FROM Posts p2 WHERE p2.Id = p.Id) AS LastEditDate
FROM
    Posts p
WHERE
    p.CommentCount IN (SELECT MAX(CommentCount) FROM Posts WHERE ParentId IS NULL)
ORDER BY
    LastEditDate DESC;

-- Using window functions to rank posts by view count
SELECT
    p.Id,
    p.Title,
    p.ViewCount,
    RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
FROM
    Posts p
WHERE
    p.CreationDate >= NOW() - INTERVAL '6 MONTH'
ORDER BY
    ViewRank;
