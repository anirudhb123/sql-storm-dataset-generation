WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadgeClass,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    rp.CommentCount,
    up.TotalBadgeClass,
    up.BadgeCount,
    pc.NetVotes
FROM 
    RankedPosts rp
JOIN 
    UserReputation up ON rp.OwnerUserId = up.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
