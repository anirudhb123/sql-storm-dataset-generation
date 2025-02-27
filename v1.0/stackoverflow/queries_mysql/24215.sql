
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        p.OwnerUserId,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS rn,
        @prev_owner_user_id := p.OwnerUserId
    FROM
        Posts p,
        (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE
        p.CreationDate >= CURDATE() - INTERVAL 30 DAY
        AND p.ViewCount > 100
        AND p.Score IS NOT NULL
    ORDER BY p.OwnerUserId, p.Score DESC
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
TopCommentedPosts AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MIN(c.CreationDate), '9999-12-31') AS FirstCommentDate
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.PostTypeId IN (1, 2)  
    GROUP BY
        p.Id
),
LastActivity AS (
    SELECT
        p.Id AS PostId,
        MAX(p.LastActivityDate) AS LatestActivity
    FROM
        Posts p
    GROUP BY
        p.Id
),
EnhancedPostDetails AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        tcp.CommentCount,
        tcp.FirstCommentDate,
        la.LatestActivity,
        @rank := @rank + 1 AS Rank
    FROM
        RankedPosts rp
    LEFT JOIN
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN
        TopCommentedPosts tcp ON rp.PostId = tcp.PostId
    LEFT JOIN
        LastActivity la ON rp.PostId = la.PostId,
        (SELECT @rank := 0) AS r
)
SELECT
    ep.PostId,
    ep.Title,
    ep.CreationDate,
    ep.Score,
    ep.ViewCount,
    ep.Tags,
    ep.GoldBadges,
    ep.SilverBadges,
    ep.BronzeBadges,
    ep.CommentCount,
    ep.FirstCommentDate,
    ep.LatestActivity,
    CASE
        WHEN ep.Score > 100 THEN 'High Score'
        WHEN ep.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE
        WHEN ep.FirstCommentDate < CURDATE() - INTERVAL 7 DAY THEN 'Stale'
        ELSE 'Recent'
    END AS CommentRecency
FROM
    EnhancedPostDetails ep
WHERE
    ep.Rank <= 50 
    AND ep.GoldBadges > 0
ORDER BY
    ep.Score DESC, 
    ep.CommentCount DESC;
