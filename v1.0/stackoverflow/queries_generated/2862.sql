WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount,
        SUM(b.Class) AS BadgeCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5
),
PopularPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank = 1
)

SELECT 
    p.Title AS PostTitle,
    u.DisplayName AS Author,
    p.ViewCount,
    p.Score,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    PopularPosts p
JOIN 
    TopUsers u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount 
     FROM Badges 
     WHERE Class = 1 
     GROUP BY UserId) b ON u.UserId = b.UserId
WHERE 
    p.Score > 5
ORDER BY 
    p.Score DESC
LIMIT 10;
