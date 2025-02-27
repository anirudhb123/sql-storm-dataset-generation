WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUBSTRING(p.Body, 1, 200) AS ShortBody,
        ARRAY_LENGTH(string_to_array(p.Tags, '>'), 1) AS TagCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Assuming we are focusing on Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
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
        rp.Rank < 4  -- Considering only the last 3 posts per user
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
    tu.UniquePosts >= 5 -- Filtering users with at least 5 unique questions
ORDER BY 
    tu.UserRank;
