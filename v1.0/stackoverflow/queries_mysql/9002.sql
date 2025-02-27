
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        @rank := IF(@prev_owner = p.OwnerUserId, @rank + 1, 1) AS Rank,
        @prev_owner := p.OwnerUserId
    FROM 
        Posts p, (SELECT @rank := 0, @prev_owner := NULL) AS vars
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56' 
        AND p.PostTypeId = 1 
    ORDER BY 
        p.OwnerUserId, p.Score DESC
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.UserId, 
        ph.PostId,
        COUNT(*) AS EditCount,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        ph.UserId, ph.PostId
)
SELECT 
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    phs.EditCount,
    phs.FirstEditDate,
    phs.LastEditDate
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.PostId IN (SELECT ph.PostId FROM PostHistory ph WHERE ph.UserId = u.Id)
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId AND u.Id = phs.UserId
WHERE 
    rp.Rank = 1 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
