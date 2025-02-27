WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) 
        AND p.Score > 0
),
UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
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
        ph.PostId,
        COUNT(DISTINCT ph.PostHistoryTypeId) AS EditTypesCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10, 11) -- Edit Title, Edit Body, Close, Reopen
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ub.UserId,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    phs.EditTypesCount,
    phs.LastEditDate,
    CASE 
        WHEN rp.CommentCount > 5 THEN 'Highly Discussed'
        WHEN rp.CommentCount BETWEEN 1 AND 5 THEN 'Moderately Discussed'
        ELSE 'No Discussion'
    END AS DiscussionLevel
FROM 
    RankedPosts rp
JOIN 
    UserBadgeStats ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.Id = phs.PostId
WHERE 
    rp.rn = 1
    AND (ub.GoldBadges > 0 OR ub.SilverBadges > 0)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
