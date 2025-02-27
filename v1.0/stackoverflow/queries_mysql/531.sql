
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
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
CloseReasons AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(cr.Name ORDER BY cr.Name SEPARATOR ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON JSON_UNQUOTE(ph.Comment->'$.CloseReasonId') = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    cr.CloseReasonNames
FROM 
    RankedPosts rp 
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON ub.UserId = up.Id
LEFT JOIN 
    CloseReasons cr ON cr.PostId = rp.PostId
WHERE 
    rp.rn = 1 
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 100;
