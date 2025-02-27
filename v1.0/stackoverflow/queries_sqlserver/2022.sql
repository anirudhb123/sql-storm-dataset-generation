
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts AS p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(DISTINCT CASE WHEN p.Id IS NOT NULL THEN p.Id END) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users AS u
    LEFT JOIN 
        Posts AS p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges AS b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopContributors AS (
    SELECT 
        us.UserId,
        us.Reputation,
        us.TotalScore,
        us.PostCount,
        us.BadgeCount,
        RANK() OVER (ORDER BY us.TotalScore DESC, us.Reputation DESC) AS UserRank
    FROM 
        UserStatistics AS us
)
SELECT 
    tc.UserId,
    tc.Reputation,
    tc.TotalScore,
    tc.PostCount,
    tc.BadgeCount,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.PostRank
FROM 
    TopContributors AS tc
LEFT JOIN 
    RankedPosts AS rp ON tc.UserId = rp.OwnerUserId
WHERE 
    tc.UserRank <= 10
ORDER BY 
    tc.TotalScore DESC, rp.Score DESC;
