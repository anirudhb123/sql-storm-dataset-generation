WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart votes
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        TotalBounty,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserReputation
    WHERE 
        PostCount > 5
)
SELECT 
    tu.UserId,
    u.DisplayName,
    u.Location,
    COALESCE(SUM(CASE WHEN rp.PostRank = 1 THEN 1 ELSE 0 END), 0) AS TopPostsCount,
    tu.TotalBounty
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
GROUP BY 
    tu.UserId, u.DisplayName, u.Location, tu.TotalBounty
HAVING 
    SUM(rp.Score) > 100
ORDER BY 
    tu.TotalBounty DESC, tu.UserRank;
