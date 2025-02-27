WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 8) OVER (PARTITION BY p.Id), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
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
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;

-- To get the count of posts that were closed or deleted along with the total score per user
SELECT 
    u.Id AS UserId,
    COUNT(DISTINCT p.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 12)) AS ClosedOrDeletedPosts,
    SUM(p.Score) AS TotalScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 5;
