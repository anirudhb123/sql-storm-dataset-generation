
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        u.Reputation,
        u.DisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
        AND p.Score > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostInteraction AS (
    SELECT 
        ct.PostId,
        COUNT(*) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount
    FROM 
        Comments ct
    LEFT JOIN 
        Votes v ON ct.PostId = v.PostId
    GROUP BY 
        ct.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.DisplayName,
    rp.Reputation,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(pi.CommentCount, 0) AS CommentCount,
    COALESCE(pi.UpvoteCount, 0) AS UpvoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostInteraction pi ON rp.PostId = pi.PostId
WHERE 
    rp.RankScore = 1
    AND (rp.Reputation > 1000 OR rp.DisplayName IS NOT NULL)
ORDER BY 
    rp.Score DESC, 
    ub.GoldBadges DESC;
