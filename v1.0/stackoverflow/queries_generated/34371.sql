WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
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

PostViews AS (
    SELECT 
        PostId,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    GROUP BY 
        PostId
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Other'
        END AS ChangeType,
        ph.CreationDate AS ChangeDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
),

FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(uv.TotalViews, 0) AS TotalViews,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        rp.CommentCount,
        ph.ChangeType,
        ph.ChangeDate,
        ph.UserDisplayName AS ModeratorUsername
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostViews uv ON rp.PostId = uv.PostId
    LEFT JOIN 
        UserBadges ub ON rp.OwnerDisplayName = ub.UserId
    LEFT JOIN 
        PostHistoryDetails ph ON rp.PostId = ph.PostId
    WHERE 
        rp.rn = 1
)

SELECT 
    *,
    CASE 
        WHEN Score > 0 THEN 'Popular'
        ELSE 'Less Popular'
    END AS PopularityStatus
FROM 
    FinalResults
WHERE 
    TotalViews > (SELECT AVG(TotalViews) FROM PostViews)
ORDER BY 
    CreationDate DESC, Score DESC;
