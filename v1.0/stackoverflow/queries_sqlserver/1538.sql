
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ISNULL(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
), TopContributors AS (
    SELECT 
        ur.UserId, 
        ur.Reputation, 
        ur.PostCount,
        ur.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC, ur.PostCount DESC) AS ContributorRank
    FROM 
        UserReputation ur
    WHERE 
        ur.PostCount > 5
)
SELECT 
    tp.UserId, 
    tp.Reputation, 
    tp.PostCount, 
    tp.TotalBounty,
    (SELECT TOP 1 p.Title FROM Posts p WHERE p.OwnerUserId = tp.UserId ORDER BY p.Score DESC) AS TopPostTitle,
    (SELECT TOP 1 p.Score FROM Posts p WHERE p.OwnerUserId = tp.UserId ORDER BY p.Score DESC) AS TopPostScore,
    (SELECT TOP 1 p.ViewCount FROM Posts p WHERE p.OwnerUserId = tp.UserId ORDER BY p.Score DESC) AS TopPostViewCount
FROM 
    TopContributors tp
WHERE 
    tp.ContributorRank <= 10
ORDER BY 
    tp.Reputation DESC, 
    tp.PostCount DESC;
