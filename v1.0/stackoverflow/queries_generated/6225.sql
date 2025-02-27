WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, a.AcceptedAnswerId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
)
SELECT 
    up.DisplayName AS Username,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.VoteCount,
    ur.Reputation,
    ur.ReputationRank
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON ur.UserId = u.Id
WHERE 
    rp.PostRank <= 5
ORDER BY 
    ur.Reputation DESC, rp.CreationDate DESC;
