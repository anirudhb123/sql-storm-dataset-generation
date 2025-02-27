WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(b.Class, 0) AS BadgeClass,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, b.Class
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        v.PostId
)
SELECT 
    p.Title,
    u.DisplayName,
    u.Reputation,
    COALESCE(b.BadgeClass, 0) AS BadgeClass,
    rp.CreationDate,
    COALESCE(rv.VoteCount, 0) AS RecentVoteCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation b ON u.Id = b.UserId
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
WHERE 
    rp.PostRank = 1 AND 
    (u.Reputation > 1000 OR b.BadgeClass = 1)
ORDER BY 
    RecentVoteCount DESC, 
    rp.CreationDate DESC
LIMIT 10;
