WITH RecursiveTags AS (
    SELECT
        Id,
        TagName,
        Count,
        COUNT(*) OVER () AS TotalTags,
        1 AS Level
    FROM Tags
    WHERE Count > 0

    UNION ALL

    SELECT
        t.Id,
        t.TagName,
        t.Count,
        rt.TotalTags,
        rt.Level + 1
    FROM RecursiveTags rt
    JOIN Tags t ON rt.Id = t.Id
    WHERE rt.Level < 3
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS PostCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(c.Score), 0) AS CommentScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id
),
PostByUser AS (
    SELECT
        u.DisplayName,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS RN
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
)
SELECT
    ua.DisplayName,
    ua.Reputation,
    rt.TagName,
    rt.TotalTags,
    SUM(COALESCE(pbu.ViewCount, 0)) AS TotalViews,
    AVG(pbu.ViewCount) AS AvgViews,
    COUNT(DISTINCT pbu.Title) AS UniquePostCount,
    STRING_AGG(DISTINCT pbu.Title, ', ') AS PostTitles
FROM UserActivity ua
LEFT JOIN RecursiveTags rt ON rt.Level = 1
LEFT JOIN PostByUser pbu ON ua.DisplayName = pbu.DisplayName AND pbu.RN <= 5
WHERE ua.Reputation >= 100
GROUP BY ua.DisplayName, ua.Reputation, rt.TagName, rt.TotalTags
HAVING COUNT(DISTINCT pbu.Title) > 0
ORDER BY ua.Reputation DESC, TotalViews DESC;
