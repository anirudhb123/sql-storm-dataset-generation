WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopDocuments AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.CommentCount 
    FROM 
        RankedPosts p
    WHERE 
        p.Rank <= 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    ud.BadgeNames,
    t.Title,
    t.Score,
    t.CommentCount,
    COALESCE(gmv.Value, 0) AS GlobalViewCount
FROM 
    Users u
INNER JOIN 
    TopDocuments t ON u.Id = t.OwnerUserId
LEFT JOIN 
    UserBadges ud ON u.Id = ud.UserId
LEFT JOIN (
    SELECT 
        p.OwnerUserId,
        SUM(p.ViewCount) AS Value
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
) gmv ON u.Id = gmv.OwnerUserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    t.Score DESC, t.CommentCount DESC
LIMIT 100;
