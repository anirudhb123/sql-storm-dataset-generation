WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8,9) -- Filtering for bounty-related votes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = u.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments WHERE UserId = u.Id) AS CommentCount
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.CommentCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    rp.TotalBounty
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.Rank = 1
WHERE 
    (us.CommentCount > 5 OR rp.PostId IS NOT NULL)
ORDER BY 
    us.Reputation DESC, rp.ViewCount DESC NULLS LAST
LIMIT 10;
