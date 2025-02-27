WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN LATERAL unnest(string_to_array(p.Tags, '><')) AS tag ON TRUE
    LEFT JOIN Tags t ON tag = t.TagName
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, u.DisplayName
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation >= 100
    GROUP BY u.Id
)
SELECT
    ur.UserId,
    ur.DisplayName,
    ur.TotalPosts,
    ur.TotalViews,
    ur.PositiveScorePosts,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags
FROM UserStats ur
JOIN RankedPosts rp ON ur.UserId = rp.OwnerDisplayName
WHERE ur.TotalPosts > 5
ORDER BY ur.TotalViews DESC, rp.Score DESC
LIMIT 100;
