WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting from Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
),

PostWithDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(ph.Level, 0) AS Level,
        p.CreationDate,
        p.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM Posts p
    LEFT JOIN PostHierarchy ph ON p.Id = ph.Id
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
),

TopPostIds AS (
    SELECT PostId
    FROM PostWithDetails
    ORDER BY Score DESC
    LIMIT 10
),

BadgesSummary AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

SELECT 
    p.Title,
    p.ViewCount,
    p.CommentCount,
    p.UpVoteCount,
    p.DownVoteCount,
    COALESCE(b.UserId, 'No badges') AS UserId,
    COALESCE(bs.BadgeCount, 0) AS BadgeCount,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges
FROM PostWithDetails p
LEFT JOIN TopPostIds t ON p.PostId = t.PostId
LEFT JOIN BadgesSummary bs ON p.PostId = bs.UserId  
WHERE p.Level = 1  -- Filter to include only top-level questions
ORDER BY p.Score DESC, p.ViewCount DESC;
