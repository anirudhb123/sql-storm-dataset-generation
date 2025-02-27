
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rnk
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Body IS NOT NULL
),
FilteredTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS Tag 
    FROM 
        RankedPosts 
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    WHERE 
        Rnk <= 10 
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        FilteredTags
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagCounts
)
SELECT 
    tt.Tag,
    tt.TagCount,
    p.Title,
    p.OwnerDisplayName,
    p.Score,
    p.ViewCount,
    p.CreationDate
FROM 
    TopTags tt
JOIN 
    RankedPosts p ON p.Tags LIKE CONCAT('%', tt.Tag, '%')
WHERE 
    tt.Rank <= 5 
ORDER BY 
    tt.TagCount DESC, p.Score DESC;
