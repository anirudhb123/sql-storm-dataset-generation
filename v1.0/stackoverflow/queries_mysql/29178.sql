
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5  
),
PostTags AS (
    SELECT 
        fp.PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        FilteredPosts fp
    INNER JOIN (
        SELECT 
            1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) n ON CHAR_LENGTH(fp.Tags) - CHAR_LENGTH(REPLACE(fp.Tags, '><', '')) >= n.n - 1
),
TagUsage AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount,
        AVG(fp.ViewCount) AS AvgViews,
        AVG(fp.Score) AS AvgScore
    FROM 
        PostTags pt
    JOIN 
        FilteredPosts fp ON pt.PostId = fp.PostId
    GROUP BY 
        Tag
    ORDER BY 
        PostCount DESC
)
SELECT 
    tu.Tag,
    tu.PostCount,
    tu.AvgViews,
    tu.AvgScore,
    GROUP_CONCAT(fp.Title ORDER BY fp.ViewCount DESC SEPARATOR ', ') AS RelatedPosts
FROM 
    TagUsage tu
JOIN 
    FilteredPosts fp ON EXISTS (
        SELECT 1 
        FROM PostTags pt 
        WHERE pt.PostId = fp.PostId AND pt.Tag = tu.Tag
    )
GROUP BY 
    tu.Tag, tu.PostCount, tu.AvgViews, tu.AvgScore
ORDER BY 
    tu.PostCount DESC, tu.AvgScore DESC
LIMIT 10;
