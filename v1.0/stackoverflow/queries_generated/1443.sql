WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
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
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.ViewCount,
    rp.CommentCount,
    ur.Reputation,
    ur.TotalBadges
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.PostId IN (SELECT b.UserId FROM Badges b WHERE b.Date >= CURRENT_DATE - INTERVAL '6 months')
WHERE 
    rp.PostRank = 1
AND 
    (ur.Reputation > 1000 OR ur.TotalBadges > 5)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 50;

UNION ALL

SELECT 
    p.Id,
    p.Title,
    p.CreationDate,
    p.Score,
    0 AS AnswerCount,
    p.ViewCount,
    0 AS CommentCount,
    u.Reputation,
    COALESCE(SUM(b.Class), 0) AS TotalBadges
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate < CURRENT_DATE - INTERVAL '6 months'
GROUP BY 
    p.Id, u.Reputation
HAVING 
    COUNT(b.Id) = 0
ORDER BY 
    p.Score DESC
LIMIT 50;
