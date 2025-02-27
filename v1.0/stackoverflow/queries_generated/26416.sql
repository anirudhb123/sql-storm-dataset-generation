WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.TagCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TagStats AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore
    FROM
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS TagRank
    FROM 
        TagStats
),
UserPostRanks AS (
    SELECT 
        ur.OwnerUserId,
        ur.PostId,
        ur.OwnerDisplayName,
        ur.PostRank,
        tt.TagName,
        tt.PostCount,
        tt.TotalViews,
        tt.TotalScore,
        tt.TagRank
    FROM 
        RankedPosts ur
    JOIN 
        TopTags tt ON tt.TagRank <= 10
)
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(up.PostId) AS UserPostCount,
    SUM(tt.TotalViews) AS UserTotalViews,
    SUM(tt.TotalScore) AS UserTotalScore,
    ARRAY_AGG(DISTINCT tt.TagName ORDER BY tt.TagName) AS UserTopTags
FROM 
    UserPostRanks up
JOIN 
    Users u ON up.OwnerUserId = u.Id
GROUP BY 
    u.DisplayName
ORDER BY 
    UserTotalScore DESC
LIMIT 10;
