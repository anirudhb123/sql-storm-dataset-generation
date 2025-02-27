
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank <= 3
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.CommentCount,
    u.DisplayName AS PostOwner,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS UserBadges
FROM 
    TopPosts p
INNER JOIN 
    Users u ON p.PostId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    p.CommentCount > 5
ORDER BY 
    p.Score DESC, p.ViewCount ASC
LIMIT 10;
