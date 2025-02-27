WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
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
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT bp.PostId) AS BestAnswers,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(SUM(pc.CommentCount), 0) AS TotalComments,
    COUNT(DISTINCT phd.ClosedDate) AS TotalClosedPosts
FROM 
    Users u
LEFT JOIN 
    RankedPosts bp ON u.Id = bp.OwnerUserId AND bp.Rank = 1
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostComments pc ON pc.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = u.Id)
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
ORDER BY 
    GoldBadges DESC, SilverBadges DESC, BronzeBadges DESC;
