
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS RankByScore,
        COALESCE(NULLIF(p.OwnerDisplayName, ''), 'Anonymous') AS OwnerDisplayName,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

PostHistoryOverview AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS IsReopened,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 ELSE 0 END) AS IsDeleted 
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    up.PostId,
    up.PostTitle,
    up.Score,
    up.ViewCount,
    up.AnswerCount,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    CASE 
        WHEN pho.IsClosed = 1 THEN 'Closed'
        WHEN pho.IsReopened = 1 THEN 'Reopened'
        WHEN pho.IsDeleted = 1 THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus
FROM 
    Users u
JOIN 
    RankedPosts up ON u.Id = up.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryOverview pho ON up.PostId = pho.PostId
WHERE 
    up.RankByScore <= 5  
    AND u.Reputation > 100  
    AND up.Score IS NOT NULL
ORDER BY 
    u.Reputation DESC, 
    up.Score DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
