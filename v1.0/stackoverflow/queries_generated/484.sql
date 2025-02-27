WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= current_date - interval '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC, TotalViews DESC) AS UserRank
    FROM 
        UserStats
    WHERE 
        PostCount > 5
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.TotalScore,
    pp.Title AS RecentPostTitle,
    pp.CreationDate AS RecentPostDate
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts pp ON tu.UserId = pp.OwnerUserId AND pp.rn = 1
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.TotalScore DESC,
    tu.TotalViews DESC;

WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    'Top Tags' AS Category,
    TagName,
    PostCount
FROM 
    TagCounts
WHERE 
    PostCount > 10
UNION ALL
SELECT 
    'Tagless Posts' AS Category,
    'N/A' AS TagName,
    COUNT(*) AS PostCount
FROM 
    Posts
WHERE 
    Tags IS NULL OR Tags = '';
