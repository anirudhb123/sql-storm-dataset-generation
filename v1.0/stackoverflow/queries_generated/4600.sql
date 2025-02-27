WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RelevantVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Score,
    ur.DisplayName,
    ur.Reputation,
    ur.TotalBadges,
    COALESCE(rv.VoteCount, 0) AS TotalVotes,
    COALESCE(rv.Upvotes, 0) AS TotalUpvotes,
    COALESCE(rv.Downvotes, 0) AS TotalDownvotes
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    RelevantVotes rv ON rp.Id = rv.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, ur.Reputation DESC
LIMIT 10;
