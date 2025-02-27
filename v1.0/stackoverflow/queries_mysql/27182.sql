
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= '2023-10-01 12:34:56' - INTERVAL 1 YEAR
),
TagAnalytics AS (
    SELECT 
        TRIM(SUBSTRING(tag, 2, CHAR_LENGTH(tag) - 2)) AS TagName,  
        COUNT(*) AS PostCount,
        COUNT(DISTINCT OwnerDisplayName) AS UniqueAuthors
    FROM 
        RankedPosts
    CROSS JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS tag
        FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        WHERE 
            CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1) AS tag
    WHERE 
        TagRank <= 5  
    GROUP BY 
        TagName
),
MostActiveTags AS (
    SELECT 
        TagName,
        PostCount,
        UniqueAuthors,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagAnalytics
)
SELECT 
    TagName,
    PostCount,
    UniqueAuthors,
    TagRank
FROM 
    MostActiveTags
WHERE 
    TagRank <= 10;
