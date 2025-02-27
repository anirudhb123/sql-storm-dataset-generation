
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AverageViews
    FROM 
        Posts
    JOIN (
        SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
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
