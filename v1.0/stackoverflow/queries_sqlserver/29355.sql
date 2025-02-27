
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS APPLY 
        (SELECT value AS TagName 
         FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS t
        ) 
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Score, p.OwnerUserId
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
    up.DisplayName,
    up.Reputation,
    up.CreationDate,
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CommentCount,
    rp.Score,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    Users up
JOIN 
    RankedPosts rp ON up.Id = rp.UserRank
JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    ub.BadgeCount > 0  
ORDER BY 
    ub.BadgeCount DESC, 
    rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
