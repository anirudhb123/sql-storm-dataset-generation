WITH TagCounts AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM
        Tags t
    JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY
        t.TagName
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounties
    FROM
        Users u
    LEFT JOIN
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON c.UserId = u.Id
    LEFT JOIN
        Votes v ON v.UserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
),
RecentEdits AS (
    SELECT
        ph.UserId,
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Body, Tags
    GROUP BY
        ph.UserId, ph.PostId
),
HighlightedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(V.CreationDate), 0) AS TotalVotes
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY
        p.Id
)
SELECT
    tc.TagName,
    tc.PostCount,
    tc.TotalViews,
    tc.TotalScore,
    ua.DisplayName AS ActiveUser,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBounties,
    ep.Title AS RecentPostTitle,
    ep.CreationDate,
    ep.Score,
    ep.ViewCount
FROM
    TagCounts tc
JOIN
    UserActivity ua ON ua.TotalPosts > 0
JOIN
    HighlightedPosts ep ON ep.CommentCount > 5
ORDER BY
    tc.TotalScore DESC,
    tc.PostCount DESC,
    ua.TotalPosts DESC
LIMIT 10;
