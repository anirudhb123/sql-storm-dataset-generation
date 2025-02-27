WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 6) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id
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
    GROUP BY 
        u.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.CommentCount,
    r.Upvotes,
    r.Downvotes,
    ur.Reputation,
    ur.BadgeCount
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
WHERE 
    r.Rank <= 5
ORDER BY 
    r.Score DESC, r.ViewCount DESC;
