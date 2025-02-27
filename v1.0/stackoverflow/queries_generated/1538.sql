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
        p.CreationDate >= NOW() - INTERVAL '1 year'
), UserReputation AS (
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
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.ViewCount AS TopPostViewCount
FROM 
    TopContributors tp
LEFT JOIN 
    RankedPosts rp ON tp.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Score = (SELECT MAX(Score) FROM Posts WHERE OwnerUserId = tp.UserId))
WHERE 
    tp.ContributorRank <= 10
ORDER BY 
    tp.Reputation DESC, 
    tp.PostCount DESC;
