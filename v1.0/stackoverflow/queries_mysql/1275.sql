
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
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UsersWithBadges AS (
    SELECT
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(b.Id) AS TotalBadgeCount
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
        u.LastAccessDate >= NOW() - INTERVAL 6 MONTH
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
LIMIT 100;
