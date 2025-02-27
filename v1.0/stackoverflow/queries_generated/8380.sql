WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS UserName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopUsers AS (
    SELECT 
        ur.Id AS UserId,
        ur.DisplayName,
        RANK() OVER (ORDER BY SUM(rp.Score) DESC) AS UserRank,
        SUM(rp.Score) AS TotalScore
    FROM 
        Users ur
    JOIN 
        RankedPosts rp ON ur.Id = rp.UserName
    GROUP BY 
        ur.Id, ur.DisplayName
    HAVING 
        COUNT(rp.Id) > 0
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.UserRank,
    tu.TotalScore,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    rp.CreationDate
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.UserName
WHERE 
    rp.RankByScore <= 5 -- Top 5 posts per user
ORDER BY 
    tu.UserRank, rp.Score DESC;
