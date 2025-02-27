
WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        @rn := IF(@prevUserId = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prevUserId := p.OwnerUserId
    FROM 
        Posts p,
        (SELECT @rn := 0, @prevUserId := NULL) AS vars
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
HighReputationUsers AS (
    SELECT 
        us.UserId,
        us.Reputation,
        us.PostCount,
        us.TotalScore
    FROM 
        UserScores us
    WHERE 
        us.Reputation > (SELECT AVG(Reputation) FROM Users)
),
TopViewCountPosts AS (
    SELECT 
        rp.Title,
        rp.ViewCount,
        rp.OwnerUserId,
        u.DisplayName,
        @rn_t := @rn_t + 1 AS rn
    FROM 
        RecentPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id,
        (SELECT @rn_t := 0) AS vars
    WHERE 
        rp.ViewCount > 100
    ORDER BY 
        rp.ViewCount DESC
)
SELECT 
    COUNT(DISTINCT h.UserId) AS UniqueHighRepUsers,
    SUM(h.Reputation) AS TotalReputation,
    AVG(t.ViewCount) AS AverageViewCount
FROM 
    HighReputationUsers h
LEFT JOIN 
    TopViewCountPosts t ON h.UserId = t.OwnerUserId
WHERE 
    t.rn <= 5
GROUP BY 
    h.UserId, h.Reputation, h.PostCount, h.TotalScore
HAVING 
    COUNT(t.Title) > 0
ORDER BY 
    TotalReputation DESC;
