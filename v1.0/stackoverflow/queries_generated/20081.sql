WITH RankedPosts AS (
    SELECT 
        p.*, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
), 
PostAnalyzed AS (
    SELECT 
        rp.*, 
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        us.TotalPosts,
        us.TotalViews,
        CASE 
            WHEN rp.CommentCount > 0 THEN 'Has Comments'
            ELSE 'No Comments'
        END AS Comment_Status,
        CASE 
            WHEN rp.LastActivityDate IS NULL THEN 'Never Active' 
            ELSE COALESCE(DATE_PART('epoch', (CURRENT_TIMESTAMP - rp.LastActivityDate)) / 3600, 0)::int::text || ' hours ago'
        END AS LastActive
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.PostRank <= 3
)

SELECT 
    pa.Title,
    pa.CreationDate,
    pa.ViewCount,
    pa.Comment_Status,
    pa.LastActive,
    pa.GoldBadges,
    pa.SilverBadges,
    pa.BronzeBadges,
    COALESCE(NULLIF(pa.TotalPosts, 0), 'No Posts') AS Post_Info,
    CASE 
        WHEN (pa.TotalViews > 10000 AND pa.CommentCount >= 5) THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS Post_Category
FROM 
    PostAnalyzed pa
WHERE 
    pa.Comment_Status = 'Has Comments' 
    OR (pa.LastActive LIKE '%hours ago' AND pa.LastActive::int <= 24)
ORDER BY 
    pa.ViewCount DESC, 
    pa.CreationDate DESC
LIMIT 20;
