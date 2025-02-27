WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
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
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 10;
