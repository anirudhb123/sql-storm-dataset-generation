WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score > (
            SELECT AVG(Score) 
            FROM Posts 
            WHERE OwnerUserId = p.OwnerUserId
        )
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT ph.PostId) AS EditCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId AND ph.PostHistoryTypeId = 24 -- Suggested Edit Applied
    GROUP BY 
        u.Id
),
RecentPostLinks AS (
    SELECT 
        pl.PostId,
        ARRAY_AGG(DISTINCT pl.RelatedPostId) AS RelatedPosts
    FROM 
        PostLinks pl
    JOIN 
        Posts p ON p.Id = pl.PostId AND p.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        pl.PostId
),
PostMetric AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        u.UserId,
        u.DisplayName,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        us.EditCount,
        COALESCE(rpl.RelatedPosts, '{}') AS RelatedPosts
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    JOIN 
        UserStats us ON u.Id = us.UserId
    LEFT JOIN 
        RecentPostLinks rpl ON rpl.PostId = rp.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.DisplayName,
    pm.GoldBadges,
    pm.SilverBadges,
    pm.BronzeBadges,
    pm.EditCount,
    NULLIF(pm.RelatedPosts::text, '{}') AS RelatedPostIds,
    CASE 
        WHEN pm.EditCount > 5 THEN 'Active Editor'
        WHEN pm.EditCount BETWEEN 1 AND 5 THEN 'Moderate Editor'
        ELSE 'New User'
    END AS EditorCategory,
    CASE 
        WHEN pm.Score IS NULL THEN 'No Score'
        WHEN pm.Score < 0 THEN 'Negative Score'
        ELSE 'Positive Score'
    END AS ScoreCategory
FROM 
    PostMetric pm
WHERE 
    pm.PostRank <= 3 -- Top 3 posts for each user
ORDER BY 
    pm.Score DESC NULLS LAST,
    pm.CreationDate DESC
LIMIT 100
OFFSET 0;


