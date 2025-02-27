
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        ur.Reputation,
        ur.TotalBadges
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.UserId = ur.UserId
    WHERE 
        rp.UserRank = 1 
        AND ur.Reputation > 100
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    CASE 
        WHEN tp.ViewCount IS NULL THEN 'Views not available'
        ELSE CONCAT(tp.ViewCount, ' views')
    END AS ViewDetails,
    CASE 
        WHEN tp.TotalBadges = 0 THEN 'No badges earned'
        ELSE CONCAT(tp.TotalBadges, ' badges earned')
    END AS BadgeInfo
FROM 
    TopPosts tp
WHERE 
    tp.Score >= (SELECT AVG(Score) FROM Posts) 
    AND tp.CommentCount > (
        SELECT AVG(CommentCount) 
        FROM (
            SELECT COUNT(*) AS CommentCount 
            FROM Comments 
            GROUP BY PostId
        ) AS CommentCounts
    )
ORDER BY 
    tp.Score DESC
LIMIT 10;
