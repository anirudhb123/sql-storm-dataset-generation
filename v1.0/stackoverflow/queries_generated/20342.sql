WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 0
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
    p.Id AS PostID,
    p.Title,
    p.OwnerUserId,
    u.DisplayName AS OwnerDisplayName,
    pb.GoldBadges,
    pb.SilverBadges,
    pb.BronzeBadges,
    COALESCE(ph.ClosedDate, ph.ReopenedDate, 'No Closure Activity') AS ClosureStatus,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
    CASE 
        WHEN p.Score IS NULL THEN 'No Score' 
        ELSE (CASE 
                WHEN p.Score >= 100 THEN 'High Score' 
                WHEN p.Score BETWEEN 50 AND 99 THEN 'Medium Score' 
                ELSE 'Low Score' 
              END) 
    END AS ScoreCategory
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges pb ON u.Id = pb.UserId
LEFT JOIN 
    PostHistoryDetails ph ON p.Id = ph.PostId
WHERE 
    (pb.GoldBadges > 0 OR pb.SilverBadges > 1) 
    AND (p.ViewCount > 10 OR ph.ClosedDate IS NOT NULL)
ORDER BY 
    p.CreationDate DESC,
    CASCADE COALESCE(pb.GoldBadges, 0) + COALESCE(pb.SilverBadges, 0) + COALESCE(pb.BronzeBadges, 0) DESC
FETCH FIRST 10 ROWS ONLY;
