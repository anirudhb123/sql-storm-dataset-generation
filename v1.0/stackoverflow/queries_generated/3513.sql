WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 /* Questions Only */
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
),

TopCommentedPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
)

SELECT 
    p.Title,
    p.ViewCount,
    u.Reputation,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN p.ViewCount > 100 THEN 'High Traffic'
        ELSE 'Normal Traffic'
    END AS Traffic_Type
FROM 
    TopCommentedPosts p
JOIN 
    Users u ON p.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN 
    UserReputation b ON u.Id = b.UserId
WHERE 
    b.BadgeCount IS NULL OR b.BadgeCount > 2
ORDER BY 
    p.ViewCount DESC;

