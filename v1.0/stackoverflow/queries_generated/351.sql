WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    tp.DisplayName,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    RankedPosts p
JOIN 
    TopUsers tp ON p.OwnerUserId = tp.UserId
LEFT JOIN 
    PostComments pc ON p.PostId = pc.PostId
LEFT JOIN 
    UserBadges ub ON tp.UserId = ub.UserId
WHERE 
    p.RN = 1
ORDER BY 
    p.Score DESC, tp.Reputation DESC;
