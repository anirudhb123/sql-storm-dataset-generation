WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostInteractions AS (
    SELECT 
        pp.PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT bh.Id) AS BadgeCount,
        SUM(CASE WHEN bh.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN bh.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN bh.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        RankedPosts pp
    LEFT JOIN Comments c ON pp.PostId = c.PostId
    LEFT JOIN Votes v ON pp.PostId = v.PostId
    LEFT JOIN Badges bh ON pp.OwnerUserId = bh.UserId
    GROUP BY 
        pp.PostId
),
PostMetrics AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Body,
        r.CreationDate,
        r.ViewCount,
        i.CommentCount,
        i.VoteCount,
        i.BadgeCount,
        i.GoldBadgeCount,
        i.SilverBadgeCount,
        i.BronzeBadgeCount
    FROM 
        RankedPosts r
    JOIN PostInteractions i ON r.PostId = i.PostId
    WHERE 
        r.Rank = 1 -- Get the most viewed question for each user
)
SELECT 
    pm.Title,
    pm.Body,
    pm.CreationDate,
    pm.ViewCount,
    pm.CommentCount,
    pm.VoteCount,
    pm.BadgeCount,
    COALESCE(pm.GoldBadgeCount, 0) AS GoldBadges,
    COALESCE(pm.SilverBadgeCount, 0) AS SilverBadges,
    COALESCE(pm.BronzeBadgeCount, 0) AS BronzeBadges,
    u.DisplayName,
    u.Reputation
FROM 
    PostMetrics pm
JOIN Users u ON pm.OwnerUserId = u.Id
ORDER BY 
    pm.ViewCount DESC
LIMIT 10;
