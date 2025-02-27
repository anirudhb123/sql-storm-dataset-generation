WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.QuestionCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score
FROM 
    UserStats u
LEFT JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId AND rp.Rank <= 5
ORDER BY 
    u.QuestionCount DESC, 
    u.Score DESC;
