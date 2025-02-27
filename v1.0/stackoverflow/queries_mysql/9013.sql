
WITH UserReputation AS (
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
        u.Id, u.DisplayName, u.Reputation
),

PostScore AS (
    SELECT 
        p.OwnerUserId,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY 
        p.OwnerUserId
),

TopContributors AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ps.TotalScore,
        ps.PostCount,
        @rank := @rank + 1 AS Rank
    FROM 
        UserReputation ur
    JOIN 
        PostScore ps ON ur.UserId = ps.OwnerUserId,
        (SELECT @rank := 0) r
    WHERE 
        ur.Reputation > 1000
    ORDER BY 
        ur.Reputation DESC, ps.TotalScore DESC
)

SELECT 
    tc.Rank,
    tc.DisplayName,
    tc.Reputation,
    tc.TotalScore,
    tc.PostCount,
    COALESCE(b.Name, 'No Badge') AS TopBadge
FROM 
    TopContributors tc
LEFT JOIN 
    (SELECT 
        UserId, 
        Name,
        @badgeRank := IF(@prevUserId = UserId, @badgeRank + 1, 1) AS BadgeRank,
        @prevUserId := UserId
    FROM 
        Badges, (SELECT @badgeRank := 0, @prevUserId := NULL) r
    ORDER BY 
        UserId, Class) b ON tc.UserId = b.UserId AND b.BadgeRank = 1
WHERE 
    tc.Rank <= 10
ORDER BY 
    tc.Rank;
