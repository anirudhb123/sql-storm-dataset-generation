WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        ROW_NUMBER() OVER (ORDER BY SUM(p.Score) DESC) AS Rank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= '2023-01-01'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ru.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    tu.TotalViews,
    tu.TotalScore
FROM 
    RankedPosts rp
JOIN 
    Users ru ON rp.OwnerUserId = ru.Id
JOIN 
    TopUsers tu ON ru.Id = tu.UserId
WHERE 
    rp.UserPostRank <= 5 AND tu.Rank <= 10
ORDER BY 
    tu.TotalScore DESC, rp.CreationDate DESC;
