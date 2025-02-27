WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (SELECT COUNT(DISTINCT b.Id) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
AverageScores AS (
    SELECT 
        p.OwnerUserId,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    ur.Reputation,
    ur.BadgeCount,
    ascores.AvgScore
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserReputation ur ON up.Id = ur.UserId
LEFT JOIN 
    AverageScores ascores ON up.Id = ascores.OwnerUserId
WHERE 
    rp.ScoreRank = 1
    AND (ur.BadgeCount > 2 OR ur.Reputation > 5000)
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 10;
