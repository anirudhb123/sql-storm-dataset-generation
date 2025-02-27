WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND p.PostTypeId = 1
)

SELECT 
    u.DisplayName, 
    u.Reputation,
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score, 
    rp.ViewCount, 
    rp.AnswerCount, 
    COALESCE(rp.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN rp.ScoreRank = 1 THEN 'Top Post' 
        ELSE 'Normal Post' 
    END AS PostRank
FROM 
    Users u
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    u.Reputation > (
        SELECT 
            AVG(Reputation) 
            FROM Users 
            WHERE Reputation IS NOT NULL
        ) 
    OR EXISTS (
        SELECT 1 
        FROM Badges b 
        WHERE b.UserId = u.Id AND b.Class = 1
    )
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 50;

WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Only include bounties
    WHERE 
        p.CreationDate < (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        p.Id
)

SELECT 
    fp.PostId, 
    fp.Title, 
    fp.TotalBounty
FROM 
    FilteredPosts fp
ORDER BY 
    fp.TotalBounty DESC
LIMIT 10;
