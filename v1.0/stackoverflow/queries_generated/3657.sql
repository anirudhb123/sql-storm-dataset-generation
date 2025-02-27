WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown'
            WHEN u.Reputation < 100 THEN 'Novice'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM 
        Users u
),
TopPosts AS (
    SELECT 
        ps.*, 
        ur.ReputationLevel
    FROM 
        PostStats ps
    JOIN 
        UserReputation ur ON ps.OwnerUserId = ur.UserId
    WHERE 
        ps.Rn = 1
)
SELECT
    t.Title,
    u.DisplayName,
    tp.ReputationLevel,
    tp.CommentCount,
    tp.TotalBounty
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON tp.OwnerUserId = u.Id
WHERE 
    tp.CommentCount > 0
ORDER BY 
    tp.TotalBounty DESC, 
    tp.CommentCount DESC;
