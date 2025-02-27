WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        CreationDate,
        CommentCount
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 5
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
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    tb.Title,
    tb.Score,
    tb.ViewCount,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    Users up
INNER JOIN 
    TopPosts tb ON up.Id = tb.OwnerUserId
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    COALESCE(ub.BadgeCount, 0) > 0
ORDER BY 
    tb.Score DESC,
    tb.ViewCount DESC;
