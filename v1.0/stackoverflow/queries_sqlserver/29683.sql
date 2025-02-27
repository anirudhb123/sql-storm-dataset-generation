
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUBSTRING(p.Body, 1, 200) AS ShortBody,
        LEN(REPLACE(p.Tags, '>', '')) - LEN(REPLACE(REPLACE(p.Tags, '>', ''), ',', '')) + 1 AS TagCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
PostStats AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT rp.PostId) AS UniquePosts,
        AVG(rp.TagCount) AS AvgTags,
        MAX(rp.CreationDate) AS LatestPostDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank < 4  
    GROUP BY 
        rp.OwnerDisplayName
),
TopUsers AS (
    SELECT 
        ps.OwnerDisplayName,
        ps.TotalPosts,
        ps.UniquePosts,
        ps.AvgTags,
        RANK() OVER(ORDER BY ps.TotalPosts DESC, ps.UniquePosts DESC) AS UserRank
    FROM 
        PostStats ps
)
SELECT 
    tu.OwnerDisplayName,
    tu.TotalPosts,
    tu.UniquePosts,
    tu.AvgTags,
    tu.UserRank,
    CASE 
        WHEN tu.UserRank <= 10 THEN 'Top Contributor'
        WHEN tu.UserRank BETWEEN 11 AND 50 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    TopUsers tu
WHERE 
    tu.UniquePosts >= 5 
ORDER BY 
    tu.UserRank;
