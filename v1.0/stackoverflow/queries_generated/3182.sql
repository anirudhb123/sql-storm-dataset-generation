WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UserRank,
        COALESCE(AVG(b.Class), 0) AS AverageBadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON rp.PostId = b.UserId
    WHERE 
        rp.UserRank <= 3
    GROUP BY 
        rp.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AverageBadgeClass
FROM 
    TopPosts tp
WHERE 
    tp.AverageBadgeClass IS NOT NULL
ORDER BY 
    tp.Score DESC
LIMIT 10;

-- Perform a correlated subquery to fetch Users with the highest Reputation
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS TotalPosts,
    (SELECT SUM(v.BountyAmount) FROM Votes v WHERE v.UserId = u.Id) AS TotalBountySpent
FROM 
    Users u
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    u.Reputation DESC
LIMIT 5;

-- Aggregate calculations
SELECT 
    p.OwnerUserId,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(v.BountyAmount) AS TotalBounty,
    AVG(p.Score) AS AverageScore,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.OwnerUserId
HAVING 
    SUM(COALESCE(v.BountyAmount, 0)) > 0
ORDER BY 
    TotalPosts DESC
LIMIT 5;
