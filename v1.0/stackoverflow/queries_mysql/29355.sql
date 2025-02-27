
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT TagName FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName 
        FROM (SELECT @row := @row + 1 AS n 
              FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
              (SELECT @row := 0) t2) n
        WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tags) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Score, p.OwnerUserId
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
LIMIT 10;
