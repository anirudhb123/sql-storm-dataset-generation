
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - 90 DAY
        AND p.PostTypeId = 1
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(*) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
    GROUP BY 
        OwnerDisplayName
    ORDER BY 
        TotalPosts DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    tu.OwnerDisplayName,
    tu.TotalPosts,
    tu.TotalViews,
    tu.TotalScore,
    STRING_AGG(p.Title, ', ' ORDER BY p.Score DESC) AS TopPostTitles
FROM 
    TopUsers tu
JOIN 
    RankedPosts p ON tu.OwnerDisplayName = p.OwnerDisplayName
GROUP BY 
    tu.OwnerDisplayName, tu.TotalPosts, tu.TotalViews, tu.TotalScore
ORDER BY 
    tu.TotalScore DESC;
