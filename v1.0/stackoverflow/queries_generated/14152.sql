-- Performance Benchmarking Query
WITH PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= '2022-01-01' -- Adjust date filter as necessary.
    GROUP BY
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
)
SELECT
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    pm.Score,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    ue.UserId,
    ue.PostsCount,
    ue.TotalViews,
    ue.GoldBadges,
    ue.SilverBadges,
    ue.BronzeBadges
FROM
    PostMetrics pm
JOIN
    UserEngagement ue ON pm.OwnerUserId = ue.UserId
ORDER BY
    pm.Score DESC, 
    pm.ViewCount DESC
LIMIT 100; -- Adjust limit as necessary for benchmarking
