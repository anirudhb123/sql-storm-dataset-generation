WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate > NOW() - INTERVAL '5 years'
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 10
)
SELECT 
    pu.UserId,
    pu.DisplayName,
    pu.TotalScore,
    pu.TotalPosts,
    rp.PostId,
    rp.Title,
    rp.Score AS PostScore,
    rp.ViewCount,
    rp.CreationDate,
    rp.CommentCount
FROM 
    TopUsers pu
JOIN 
    RankedPosts rp ON pu.UserId = rp.OwnerUserId
WHERE 
    rp.RankByScore <= 3 -- Get top 3 posts per user
ORDER BY 
    pu.TotalScore DESC, 
    rp.Score DESC;
