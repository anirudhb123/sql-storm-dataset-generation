
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        @rank := @rank + 1 AS ReputationRank
    FROM 
        Users u,
        (SELECT @rank := 0) r
    WHERE 
        u.Reputation IS NOT NULL
    AND 
        u.Reputation > 1000
    ORDER BY 
        u.Reputation DESC
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.TotalBounty,
        @postRank := @postRank + 1 AS PostRank
    FROM 
        RecentPosts rp,
        (SELECT @postRank := 0) r
    ORDER BY 
        rp.CommentCount DESC, rp.TotalBounty DESC
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.TotalBounty
FROM 
    UserReputation ur
JOIN 
    Posts p ON ur.UserId = p.OwnerUserId
JOIN 
    TopPosts tp ON p.Id = tp.PostId
WHERE 
    tp.PostRank <= 10
AND 
    (ur.Reputation > 2000 OR tp.TotalBounty > 0)
ORDER BY 
    ur.Reputation DESC, tp.CommentCount DESC;
