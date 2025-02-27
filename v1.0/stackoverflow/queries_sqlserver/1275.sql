
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UsersWithBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(b.Class) AS TotalBadgeCount
    FROM
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.UserId = u.Id) AS CommentCount
    FROM 
        Users u
    WHERE 
        u.LastAccessDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 6 MONTH
)
SELECT 
    au.DisplayName,
    au.Reputation,
    COALESCE(rb.CommentCount, 0) AS PostsCommentCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rb.Title AS MostRecentPostTitle,
    rb.Score AS MostRecentPostScore
FROM 
    ActiveUsers au
LEFT JOIN 
    UsersWithBadges ub ON au.Id = ub.UserId
LEFT JOIN 
    RankedPosts rb ON au.Id = rb.OwnerUserId AND rb.OwnerPostRank = 1
WHERE 
    au.PostCount > 5
ORDER BY 
    au.Reputation DESC, MostRecentPostScore DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
