
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 8 THEN v.BountyAmount ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS TotalBounty,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.TotalBounty,
        ur.Reputation,
        ur.PostCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        ur.Reputation > 500 AND rp.rn = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CommentCount,
    fp.TotalBounty,
    fp.Reputation,
    fp.PostCount,
    CASE 
        WHEN fp.Reputation > 1000 THEN 'High Reputation User'
        WHEN fp.Reputation > 500 THEN 'Medium Reputation User'
        ELSE 'Low Reputation User'
    END AS UserReputationLevel
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, fp.TotalBounty DESC
LIMIT 20 OFFSET 10;
