WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
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
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY 
        ph.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        UserBadges ub ON rp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ub.UserId)
)
SELECT 
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.CloseCount,
    pd.GoldBadges,
    pd.SilverBadges,
    pd.BronzeBadges,
    CASE 
        WHEN pd.CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN pd.Score >= 50 THEN 'High Score'
        WHEN pd.Score BETWEEN 10 AND 49 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CONCAT('View Count: ', pd.ViewCount, ' | Score: ', pd.Score) AS ViewScoreInfo
FROM 
    PostDetails pd
WHERE 
    pd.Rank <= 5 -- Top 5 posts per type
ORDER BY 
    pd.Score DESC,
    pd.ViewCount DESC;
