WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ub.UserId,
        ub.BadgeCount,
        COALESCE(ub.GoldCount, 0) AS GoldCount,
        COALESCE(ub.SilverCount, 0) AS SilverCount,
        COALESCE(ub.BronzeCount, 0) AS BronzeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        rp.UserRank <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    CASE 
        WHEN tp.BadgeCount > 0 THEN 'Has Badges' 
        ELSE 'No Badges' 
    END AS BadgeStatus,
    CONCAT('Gold: ', tp.GoldCount, ', Silver: ', tp.SilverCount, ', Bronze: ', tp.BronzeCount) AS BadgeDetails
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC
LIMIT 10;

-- This query retrieves the top 5 posts from each user within the last year, along with user badge information, 
-- applying complex functions like row numbering, conditional aggregation, and string concatenation.
