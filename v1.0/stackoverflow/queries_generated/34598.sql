WITH RecursiveTagCTE AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, IsModeratorOnly, IsRequired
    FROM Tags
    WHERE Count > 100 -- Only consider popular tags
    UNION ALL
    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, t.IsModeratorOnly, t.IsRequired
    FROM Tags t
    INNER JOIN RecursiveTagCTE r ON t.ExcerptPostId = r.Id
),
RecentPostCTE AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days' -- Recent posts
    GROUP BY p.Id
),
UserBadgesCTE AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    pt.TagName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ub.DisplayName AS Owner,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rp.CommentCount,
    CASE 
        WHEN rp.AcceptedAnswerId != -1 THEN (SELECT COUNT(*) FROM Posts ap WHERE ap.Id = rp.AcceptedAnswerId AND ap.OwnerUserId = rp.OwnerUserId)
        ELSE 0
    END AS AcceptedAnswersCount
FROM RecursiveTagCTE pt
JOIN RecentPostCTE rp ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || pt.TagName || '%') 
JOIN UserBadgesCTE ub ON rp.OwnerUserId = ub.UserId
WHERE ub.BadgeCount > 0 AND rp.Score > 0
ORDER BY pt.TagName, rp.Score DESC;
