
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
PostStats AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(rp.PostId) AS TotalQuestions,
        AVG(rp.Score) AS AverageScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 
    GROUP BY 
        rp.OwnerDisplayName
),
TopUsers AS (
    SELECT 
        ps.OwnerDisplayName,
        ps.TotalQuestions,
        ps.AverageScore,
        ps.TotalViews,
        RANK() OVER (ORDER BY ps.TotalQuestions DESC) AS Rank
    FROM 
        PostStats ps
)
SELECT 
    tu.Rank,
    tu.OwnerDisplayName,
    tu.TotalQuestions,
    tu.AverageScore,
    tu.TotalViews
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
