
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.ViewCount > 1000
),
TagStats AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AverageViews
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        AverageViews,
        RANK() OVER (ORDER BY AverageViews DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.CreationDate,
    tt.TagName,
    tt.PostCount,
    tt.AverageViews
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON rp.TagRank = 1
WHERE 
    tt.TagRank <= 5
ORDER BY 
    tt.AverageViews DESC, rp.CreationDate DESC;
