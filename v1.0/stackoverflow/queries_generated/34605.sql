WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(v.Id) AS VoteCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1.0 ELSE 0 END) AS UpvoteRatio
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    INNER JOIN 
        Users ub ON b.UserId = ub.Id
    WHERE 
        ub.Reputation > 1000 
    GROUP BY 
        ub.UserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    p.ViewCount,
    p.Score,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    ph.CloseCount,
    ph.ReopenCount,
    ph.EditCount,
    rp.RankByScore,
    rp.UpvoteRatio
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    UserBadges ub ON p.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistorySummary ph ON p.Id = ph.PostId
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
