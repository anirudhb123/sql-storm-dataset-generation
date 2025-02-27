
WITH ParsedTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers, (SELECT @row := 0) r) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        ParsedTags
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount
    FROM 
        TagCounts
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
TagDetails AS (
    SELECT 
        p.Title,
        p.Id AS PostId,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        t.Tag
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        ParsedTags pt ON p.Id = pt.PostId
    JOIN 
        TopTags t ON pt.Tag = t.Tag
)
SELECT
    Tag,
    COUNT(*) AS PostCount,
    AVG(Score) AS AverageScore,
    MIN(CreationDate) AS EarliestCreation,
    MAX(CreationDate) AS LatestCreation,
    GROUP_CONCAT(DISTINCT Title SEPARATOR '; ') AS RelatedPostTitles,
    GROUP_CONCAT(DISTINCT OwnerDisplayName SEPARATOR '; ') AS Contributors
FROM
    TagDetails
GROUP BY 
    Tag
ORDER BY 
    PostCount DESC;
