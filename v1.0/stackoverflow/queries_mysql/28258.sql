
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagFrequency
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5  
),
PopularTags AS (
    SELECT 
        tc.TagName,
        tc.TagFrequency,
        COUNT(*) AS PostCount,
        RANK() OVER (ORDER BY tc.TagFrequency DESC) AS FrequencyRank
    FROM 
        TagCounts tc
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', tc.TagName, '%')
    GROUP BY 
        tc.TagName, tc.TagFrequency
)
SELECT 
    r.PostId,
    r.Title,
    r.ViewCount,
    r.OwnerDisplayName,
    p.TagName,
    p.TagFrequency,
    p.PostCount
FROM 
    RankedPosts r
JOIN 
    PopularTags p ON p.PostCount > 0
WHERE 
    r.ViewRank <= 10  
ORDER BY 
    r.ViewCount DESC, 
    p.TagFrequency DESC;
