WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    u.DisplayName,
    ur.Reputation,
    ur.TotalPosts,
    ur.TotalBadges,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.CommentCount,
    rp.VoteCount
FROM 
    UserReputation ur
JOIN 
    Users u ON ur.UserId = u.Id
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    ur.Reputation > 1000
    AND rp.Rank <= 5
ORDER BY 
    ur.Reputation DESC, rp.Score DESC;
