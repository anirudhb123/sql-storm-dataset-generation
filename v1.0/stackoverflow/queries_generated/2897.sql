WITH UserBadgeCounts AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadgeCount,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadgeCount,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadgeCount
    FROM
        Badges
    GROUP BY 
        UserId
),
PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
RankedPosts AS (
    SELECT 
        pm.PostId, 
        pm.Title, 
        pm.Score, 
        pm.UpVoteCount, 
        pm.DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY pm.OwnerUserId ORDER BY pm.Score DESC) AS PostRank
    FROM 
        PostMetrics pm
)
SELECT 
    u.DisplayName,
    upb.GoldBadgeCount,
    upb.SilverBadgeCount,
    upb.BronzeBadgeCount,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.UpVoteCount,
    rp.DownVoteCount
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts upb ON u.Id = upb.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    (upb.GoldBadgeCount IS NOT NULL OR upb.SilverBadgeCount IS NOT NULL OR upb.BronzeBadgeCount IS NOT NULL)
    AND rp.PostRank <= 3
ORDER BY
    COALESCE(upb.GoldBadgeCount, 0) DESC,
    COALESCE(upb.SilverBadgeCount, 0) DESC,
    COALESCE(upb.BronzeBadgeCount, 0) DESC,
    rp.Score DESC;
